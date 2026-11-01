import Foundation
import SwiftData

enum CashUpPersistence {
    static let schema = Schema(versionedSchema: SchemaAtual.self)

    /// Localização padrão: store antigo em `Application Support` e store do App Group, quando o container do grupo existe.
    ///
    /// O local antigo é montado à mão: com o entitlement de App Group, o `ModelConfiguration` padrão do SwiftData
    /// passa a apontar para o container do grupo, então `ModelConfiguration(schema:).url` deixaria de ser o store antigo.
    static func localizacaoPadrao() -> StoreLocalizacao {
        let antigo = URL.applicationSupportDirectory.appendingPathComponent("default.store")
        guard FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: CashUpAppGroup.identificador) != nil else {
            return StoreLocalizacao(antigo: antigo, grupo: nil)
        }
        let grupo = ModelConfiguration(schema: schema, groupContainer: .identifier(CashUpAppGroup.identificador)).url
        return StoreLocalizacao(antigo: antigo, grupo: grupo)
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
    /// Sem container de grupo (simulador/teste sem entitlement), segue no local antigo e não move nada.
    /// O store antigo só é apagado depois que o container novo abre; se a abertura falhar, ele continua intacto.
    static func makeContainer(localizacao: StoreLocalizacao, operacoes: StoreLocationMigrator.Operacoes = .padrao) throws -> ModelContainer {
        guard let grupo = localizacao.grupo else {
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
        let container = try makeContainer(url: grupo)
        migrador.concluirMigracao()
        return container
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
