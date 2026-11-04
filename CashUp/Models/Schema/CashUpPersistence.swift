import Foundation
import SwiftData

enum CashUpPersistence {
    static let schema = Schema(versionedSchema: SchemaAtual.self)

    /// Localização padrão: store antigo em `Application Support` e store do App Group, quando o container do grupo existe.
    /// A sentinela fica no `Application Support` do app, fora do grupo, e marca "este aparelho já usa o store do grupo".
    ///
    /// O local antigo é montado à mão: com o entitlement de App Group, o `ModelConfiguration` padrão do SwiftData
    /// passa a apontar para o container do grupo, então `ModelConfiguration(schema:).url` deixaria de ser o store antigo.
    static func localizacaoPadrao() -> StoreLocalizacao {
        let antigo = URL.applicationSupportDirectory.appendingPathComponent("default.store")
        let sentinela = URL.applicationSupportDirectory.appendingPathComponent("default.store.no-app-group")
        guard FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: CashUpAppGroup.identificador) != nil else {
            return StoreLocalizacao(antigo: antigo, grupo: nil, sentinela: sentinela)
        }
        let grupo = ModelConfiguration(schema: schema, groupContainer: .identifier(CashUpAppGroup.identificador)).url
        return StoreLocalizacao(antigo: antigo, grupo: grupo, sentinela: sentinela)
    }

    static func makeContainer(inMemory: Bool) throws -> ModelContainer {
        if inMemory {
            return try makeContainer(configuration: ModelConfiguration(schema: schema, isStoredInMemoryOnly: true))
        }
        return try makeContainer(localizacao: localizacaoPadrao())
    }

    static func makeContainer(url: URL) throws -> ModelContainer {
        try makeContainer(configuration: ModelConfiguration(schema: schema, url: url))
    }

    /// Abre o store no App Group, copiando antes o store do local antigo se for o caso.
    /// Sem container de grupo (build sem o entitlement), segue no local antigo e não move nada, a menos que a sentinela
    /// diga que o store já mora no grupo: aí lança `StoreLocalizacaoErro.grupoIndisponivel` em vez de criar um store vazio
    /// no local antigo (o app cai no fallback em memória e avisa o usuário).
    /// O store antigo só é apagado depois que o container novo abre; se a abertura falhar, ele continua intacto e a cópia
    /// ainda não aberta é descartada, para recopiar do original na próxima abertura.
    static func makeContainer(localizacao: StoreLocalizacao, operacoes: StoreLocationMigrator.Operacoes = .padrao) throws -> ModelContainer {
        guard let grupo = localizacao.grupo else {
            if let sentinela = localizacao.sentinela, FileManager.default.fileExists(atPath: sentinela.path) {
                CashUpLogger.persistence.fault("App Group indisponível e o store já foi movido para ele; não vou criar um store vazio no local antigo")
                throw StoreLocalizacaoErro.grupoIndisponivel
            }
            return try makeContainer(url: localizacao.antigo)
        }

        let migrador = StoreLocationMigrator(antigo: localizacao.antigo, grupo: grupo, operacoes: operacoes)
        do {
            try migrador.prepararGrupo()
        } catch {
            // Cópia falhou: o grupo ficou limpo e o antigo intacto. Abre no antigo e tenta de novo na próxima abertura.
            CashUpLogger.persistence.error("Migração do store para o App Group falhou: \(error.localizedDescription, privacy: .public)")
            return try makeContainer(url: localizacao.antigo)
        }

        try FileManager.default.createDirectory(at: grupo.deletingLastPathComponent(), withIntermediateDirectories: true)
        let container: ModelContainer
        do {
            container = try makeContainer(url: grupo)
        } catch {
            migrador.descartarCopiaNaoAberta()
            throw error
        }
        gravarSentinela(localizacao.sentinela)
        migrador.concluirMigracao()
        return container
    }

    private static func gravarSentinela(_ sentinela: URL?) {
        guard let sentinela, !FileManager.default.fileExists(atPath: sentinela.path) else { return }
        do {
            try FileManager.default.createDirectory(at: sentinela.deletingLastPathComponent(), withIntermediateDirectories: true)
            guard FileManager.default.createFile(atPath: sentinela.path, contents: nil) else { throw CocoaError(.fileWriteUnknown) }
        } catch {
            CashUpLogger.persistence.error("Não foi possível gravar a sentinela do App Group: \(error.localizedDescription, privacy: .public)")
        }
    }

    private static func makeContainer(configuration: ModelConfiguration) throws -> ModelContainer {
        let container = try ModelContainer(for: schema, migrationPlan: CashUpMigrationPlan.self, configurations: configuration)
        let contexto = ModelContext(container)
        if try CashUpMigrationPlan.vincularTransacoesPendentesAContaPadrao(em: contexto) > 0 {
            try contexto.save()
        }
        return container
    }
}
