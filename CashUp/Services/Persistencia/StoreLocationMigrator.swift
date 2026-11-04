import Foundation

/// Identificador do App Group que guarda o store compartilhado com widgets e extensões.
enum CashUpAppGroup {
    static let identificador = "group.br.com.gustavosouto.cashup"
}

/// Onde o store mora: o local antigo (`Application Support` do app) e o do App Group.
/// `grupo` é `nil` quando o container do grupo não está disponível (build sem o entitlement/assinatura).
/// `sentinela` é um arquivo no container do app (fora do grupo) gravado depois da primeira abertura bem-sucedida no grupo:
/// com ele presente e o grupo indisponível, o app não pode abrir um store vazio no local antigo.
struct StoreLocalizacao {
    let antigo: URL
    let grupo: URL?
    let sentinela: URL?

    init(antigo: URL, grupo: URL?, sentinela: URL? = nil) {
        self.antigo = antigo
        self.grupo = grupo
        self.sentinela = sentinela
    }
}

enum StoreLocalizacaoErro: Error, LocalizedError {
    /// O store já mora no App Group, mas o container do grupo não está disponível agora.
    case grupoIndisponivel

    var errorDescription: String? {
        switch self {
        case .grupoIndisponivel:
            return "O container do App Group não está disponível e o store já foi movido para ele."
        }
    }
}

/// Move o store do local antigo para o container do App Group, sem nunca deixar um store de grupo inválido
/// e sem apagar o original antes de o `ModelContainer` novo abrir.
///
/// Um "store" são quatro itens ao lado um do outro: `default.store`, `-wal`, `-shm` e o diretório de dados externos do
/// Core Data (`.default_SUPPORT`, onde ficam os valores `.externalStorage` grandes, como `ExpenseModel.repetition`).
/// Todos são copiados, movidos e apagados juntos, sempre com o `.store` por último nos movimentos.
///
/// Fluxo (rodar **antes** de abrir o `ModelContainer`):
/// 1. `prepararGrupo()` copia o store para uma pasta temporária ao lado do destino e só então move os itens para o lugar,
///    com o `.store` por último. A existência do `.store` no grupo é o marcador de "cópia completa";
///    uma cópia interrompida deixa no máximo itens soltos, que a tentativa seguinte descarta.
///    O marcador `.migracao-pendente` diz "copiado e nunca aberto".
/// 2. O app abre o container no local do grupo. Se a abertura falhar com o marcador pendente e o antigo existindo,
///    `descartarCopiaNaoAberta()` apaga a cópia (possivelmente meio migrada) para recopiar do original na próxima abertura.
/// 3. `concluirMigracao()` renomeia o marcador para `.migracao-limpeza` ("aberto, falta limpar") e só então apaga o antigo.
///    A limpeza é retomável a partir de `.migracao-limpeza`. O antigo nunca é apagado se foi alterado depois da cópia.
struct StoreLocationMigrator {
    enum Resultado: Equatable {
        /// Não havia store antigo (instalação nova): nada a fazer.
        case semStoreAntigo
        /// O store do grupo já existe: nunca é sobrescrito.
        case grupoJaExistia
        /// O store antigo foi copiado para o grupo.
        case copiado
    }

    /// Operações de arquivo injetáveis para simular falhas no meio da cópia.
    struct Operacoes {
        var copiar: (URL, URL) throws -> Void
        var mover: (URL, URL) throws -> Void

        static let padrao = Operacoes(
            copiar: { try FileManager.default.copyItem(at: $0, to: $1) },
            mover: { try FileManager.default.moveItem(at: $0, to: $1) }
        )
    }

    private static let prefixoTemporario = ".migracao-"
    private static let sufixoMarcadorPendente = ".migracao-pendente"
    private static let sufixoMarcadorLimpeza = ".migracao-limpeza"
    /// Folga ao comparar a data do antigo com a do marcador: o fechamento tardio de uma conexão SQLite (checkpoint do WAL)
    /// logo depois da cópia não é uma gravação de dados; uma alteração real chega segundos depois, numa abertura seguinte.
    private static let folgaDeRelogio: TimeInterval = 2

    let antigo: URL
    let grupo: URL
    var operacoes: Operacoes = .padrao
    private let fileManager = FileManager.default

    init(antigo: URL, grupo: URL, operacoes: Operacoes = .padrao) {
        self.antigo = antigo
        self.grupo = grupo
        self.operacoes = operacoes
    }

    @discardableResult
    func prepararGrupo() throws -> Resultado {
        if fileManager.fileExists(atPath: grupo.path) {
            // Depois do commit, uma pasta temporária vazia pode sobrar de um encerramento antes de removê-la.
            removerPastasTemporariasVazias()
            if fileManager.fileExists(atPath: antigo.path), !existeMarcador {
                CashUpLogger.persistence.error("Store do App Group já existe e há um store antigo sem marcador de migração; o antigo não foi tocado e pode conter dados fora do grupo")
            }
            return .grupoJaExistia
        }

        // Sem o `.store` do grupo, qualquer auxiliar, marcador ou pasta temporária é resíduo de uma tentativa interrompida.
        limparResiduosDoGrupo()

        guard fileManager.fileExists(atPath: antigo.path) else {
            return .semStoreAntigo
        }

        let pastaDoGrupo = grupo.deletingLastPathComponent()
        try fileManager.createDirectory(at: pastaDoGrupo, withIntermediateDirectories: true)

        let temporaria = pastaDoGrupo.appendingPathComponent(Self.prefixoTemporario + UUID().uuidString, isDirectory: true)
        do {
            try fileManager.createDirectory(at: temporaria, withIntermediateDirectories: true)

            // Cada item do antigo tem o seu destino derivado do nome do arquivo do GRUPO (o nome pode diferir do antigo).
            let pares = zip(arquivosDoStore(antigo), arquivosDoStore(grupo)).filter { fileManager.fileExists(atPath: $0.0.path) }

            // Cópia para a pasta temporária; o store de grupo ainda não existe.
            for (origem, destino) in pares {
                try operacoes.copiar(origem, temporaria.appendingPathComponent(destino.lastPathComponent))
            }

            // Move os auxiliares primeiro (`-wal`, `-shm`, dados externos), depois o marcador, e o `.store` por último: ele é o ponto de commit.
            for (_, destino) in pares where destino != grupo {
                try operacoes.mover(temporaria.appendingPathComponent(destino.lastPathComponent), destino)
            }
            guard fileManager.createFile(atPath: marcadorPendente.path, contents: nil) else {
                throw CocoaError(.fileWriteUnknown)
            }
            try operacoes.mover(temporaria.appendingPathComponent(grupo.lastPathComponent), grupo)
        } catch {
            limparResiduosDoGrupo()
            throw error
        }

        try? fileManager.removeItem(at: temporaria)
        return .copiado
    }

    /// Chamar quando o container do grupo falhar ao abrir. Se a cópia foi feita por este fluxo e nunca chegou a abrir
    /// (marcador pendente) e o antigo existe, apaga a cópia do grupo (`.store` primeiro) para recopiar do original na próxima abertura:
    /// uma cópia cuja migração de schema falhou no meio não pode ser reaproveitada nem autorizar a exclusão do antigo.
    func descartarCopiaNaoAberta() {
        guard fileManager.fileExists(atPath: marcadorPendente.path), fileManager.fileExists(atPath: antigo.path) else { return }
        try? fileManager.removeItem(at: grupo)
        limparResiduosDoGrupo()
    }

    /// Chamar depois de o container do grupo abrir com sucesso. Apaga o store antigo se (e só se) ele foi migrado por este fluxo.
    func concluirMigracao() {
        let marcador: URL
        if fileManager.fileExists(atPath: marcadorLimpeza.path) {
            marcador = marcadorLimpeza
        } else if fileManager.fileExists(atPath: marcadorPendente.path) {
            marcador = marcadorPendente
        } else {
            return
        }
        guard fileManager.fileExists(atPath: grupo.path) else {
            try? fileManager.removeItem(at: marcador)
            return
        }
        if antigoFoiAlteradoDepoisDe(marcador) {
            CashUpLogger.persistence.fault("Store antigo alterado depois da cópia para o App Group; não foi apagado e pode conter dados fora do grupo")
            try? fileManager.removeItem(at: marcador)
            return
        }
        if marcador == marcadorPendente {
            // A partir daqui o grupo foi aberto: a cópia não é mais descartável, só falta limpar o antigo.
            do {
                try fileManager.moveItem(at: marcadorPendente, to: marcadorLimpeza)
            } catch {
                CashUpLogger.persistence.error("Não foi possível marcar a limpeza do store antigo: \(error.localizedDescription, privacy: .public)")
                return
            }
        }
        apagarAntigo()
    }

    // MARK: - Privado

    private var marcadorPendente: URL {
        URL(fileURLWithPath: grupo.path + Self.sufixoMarcadorPendente)
    }

    private var marcadorLimpeza: URL {
        URL(fileURLWithPath: grupo.path + Self.sufixoMarcadorLimpeza)
    }

    private var existeMarcador: Bool {
        fileManager.fileExists(atPath: marcadorPendente.path) || fileManager.fileExists(atPath: marcadorLimpeza.path)
    }

    /// Os itens de um store, com o `.store` primeiro e o diretório de dados externos do Core Data (`.<nome>_SUPPORT`) por último.
    /// A ordem é a mesma para o antigo e para o grupo, então os dois podem ser pareados por posição.
    private func arquivosDoStore(_ principal: URL) -> [URL] {
        let nomeSemExtensao = principal.deletingPathExtension().lastPathComponent
        let suporte = principal.deletingLastPathComponent().appendingPathComponent(".\(nomeSemExtensao)_SUPPORT", isDirectory: true)
        return [
            principal,
            URL(fileURLWithPath: principal.path + "-wal"),
            URL(fileURLWithPath: principal.path + "-shm"),
            suporte
        ]
    }

    /// `.store` ou `-wal` do antigo mais novos que o marcador (além da folga) significam gravações feitas depois da cópia.
    private func antigoFoiAlteradoDepoisDe(_ marcador: URL) -> Bool {
        guard let dataDoMarcador = modificacao(de: marcador) else { return false }
        let observados = arquivosDoStore(antigo).prefix(2)
        return observados.contains { arquivo in
            guard let data = modificacao(de: arquivo) else { return false }
            return data > dataDoMarcador.addingTimeInterval(Self.folgaDeRelogio)
        }
    }

    private func modificacao(de url: URL) -> Date? {
        (try? fileManager.attributesOfItem(atPath: url.path))?[.modificationDate] as? Date
    }

    /// Apaga o antigo, com o `.store` por último, e só remove o marcador de limpeza quando não sobrar nada dele.
    /// Se a exclusão for interrompida ou falhar, o marcador continua e a próxima abertura retoma daqui.
    private func apagarAntigo() {
        for arquivo in arquivosDoStore(antigo).reversed() where fileManager.fileExists(atPath: arquivo.path) {
            do {
                try fileManager.removeItem(at: arquivo)
            } catch {
                CashUpLogger.persistence.error("Não foi possível apagar \(arquivo.lastPathComponent, privacy: .public) do store antigo: \(error.localizedDescription, privacy: .public)")
            }
        }
        if !arquivosDoStore(antigo).contains(where: { fileManager.fileExists(atPath: $0.path) }) {
            try? fileManager.removeItem(at: marcadorLimpeza)
        }
    }

    /// Remove tudo o que cerca um `.store` de grupo que não existe (ou que está sendo descartado), menos o próprio `.store`.
    private func limparResiduosDoGrupo() {
        for arquivo in arquivosDoStore(grupo).dropFirst() + [marcadorPendente, marcadorLimpeza] {
            try? fileManager.removeItem(at: arquivo)
        }
        let pasta = grupo.deletingLastPathComponent()
        let itens = (try? fileManager.contentsOfDirectory(atPath: pasta.path)) ?? []
        for item in itens where item.hasPrefix(Self.prefixoTemporario) {
            try? fileManager.removeItem(at: pasta.appendingPathComponent(item))
        }
    }

    private func removerPastasTemporariasVazias() {
        let pasta = grupo.deletingLastPathComponent()
        let itens = (try? fileManager.contentsOfDirectory(atPath: pasta.path)) ?? []
        for item in itens where item.hasPrefix(Self.prefixoTemporario) {
            let url = pasta.appendingPathComponent(item)
            if ((try? fileManager.contentsOfDirectory(atPath: url.path)) ?? ["?"]).isEmpty {
                try? fileManager.removeItem(at: url)
            }
        }
    }
}
