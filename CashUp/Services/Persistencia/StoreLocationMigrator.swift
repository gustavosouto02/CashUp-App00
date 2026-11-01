import Foundation

/// Identificador do App Group que guarda o store compartilhado com widgets e extensões.
enum CashUpAppGroup {
    static let identificador = "group.br.com.gustavosouto.cashup"
}

/// Onde o store mora: o local antigo (`Application Support` do app) e o do App Group.
/// `grupo` é `nil` quando o container do grupo não está disponível (sem entitlement/assinatura).
struct StoreLocalizacao {
    let antigo: URL
    let grupo: URL?
}

/// Move o store do local antigo para o container do App Group, sem nunca deixar um store de grupo inválido
/// e sem apagar o original antes de o `ModelContainer` novo abrir.
///
/// Fluxo (rodar **antes** de abrir o `ModelContainer`):
/// 1. `prepararGrupo()` copia `default.store`, `-wal` e `-shm` para uma pasta temporária ao lado do destino e só então
///    move os arquivos para o lugar, com o `.store` por último. A existência do `.store` no grupo é o marcador de "cópia completa";
///    uma cópia interrompida deixa no máximo arquivos soltos, que a tentativa seguinte descarta.
/// 2. O app abre o container no local do grupo.
/// 3. `concluirMigracao()` apaga o store antigo, e só se a cópia foi feita por este fluxo (marcador de migração pendente).
///    Se o app for encerrado entre abrir e apagar, o marcador faz a próxima abertura terminar a limpeza.
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
    private static let sufixoMarcador = ".migracao-pendente"

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
            return .grupoJaExistia
        }

        // Sem o `.store` do grupo, qualquer `-wal`, `-shm`, marcador ou pasta temporária é resíduo de uma tentativa interrompida.
        limparResiduosDoGrupo()

        guard fileManager.fileExists(atPath: antigo.path) else {
            return .semStoreAntigo
        }

        let pastaDoGrupo = grupo.deletingLastPathComponent()
        try fileManager.createDirectory(at: pastaDoGrupo, withIntermediateDirectories: true)

        let temporaria = pastaDoGrupo.appendingPathComponent(Self.prefixoTemporario + UUID().uuidString, isDirectory: true)
        do {
            try fileManager.createDirectory(at: temporaria, withIntermediateDirectories: true)

            // Cópia para a pasta temporária; o store de grupo ainda não existe.
            let arquivos = arquivosDoStore(antigo).filter { fileManager.fileExists(atPath: $0.path) }
            for origem in arquivos {
                try operacoes.copiar(origem, temporaria.appendingPathComponent(origem.lastPathComponent))
            }

            // Move `-wal` e `-shm` primeiro, depois o marcador, e o `.store` por último: ele é o ponto de commit.
            let auxiliares = arquivos.filter { $0 != antigo }
            for origem in auxiliares {
                let destino = pastaDoGrupo.appendingPathComponent(origem.lastPathComponent)
                try operacoes.mover(temporaria.appendingPathComponent(origem.lastPathComponent), destino)
            }
            guard fileManager.createFile(atPath: marcador.path, contents: nil) else {
                throw CocoaError(.fileWriteUnknown)
            }
            try operacoes.mover(temporaria.appendingPathComponent(antigo.lastPathComponent), grupo)
        } catch {
            limparResiduosDoGrupo()
            throw error
        }

        try? fileManager.removeItem(at: temporaria)
        return .copiado
    }

    /// Chamar depois de o container do grupo abrir com sucesso. Apaga o store antigo se (e só se) ele foi migrado por este fluxo.
    func concluirMigracao() {
        guard fileManager.fileExists(atPath: marcador.path) else { return }
        guard fileManager.fileExists(atPath: grupo.path) else {
            try? fileManager.removeItem(at: marcador)
            return
        }
        // `.store` por último: se for interrompido no meio, o marcador continua e a próxima abertura termina o trabalho.
        for arquivo in arquivosDoStore(antigo).reversed() where fileManager.fileExists(atPath: arquivo.path) {
            try? fileManager.removeItem(at: arquivo)
        }
        try? fileManager.removeItem(at: marcador)
    }

    // MARK: - Privado

    private var marcador: URL {
        URL(fileURLWithPath: grupo.path + Self.sufixoMarcador)
    }

    private func arquivosDoStore(_ principal: URL) -> [URL] {
        [principal, URL(fileURLWithPath: principal.path + "-wal"), URL(fileURLWithPath: principal.path + "-shm")]
    }

    private func limparResiduosDoGrupo() {
        for arquivo in arquivosDoStore(grupo).dropFirst() + [marcador] {
            try? fileManager.removeItem(at: arquivo)
        }
        let pasta = grupo.deletingLastPathComponent()
        let itens = (try? fileManager.contentsOfDirectory(atPath: pasta.path)) ?? []
        for item in itens where item.hasPrefix(Self.prefixoTemporario) {
            try? fileManager.removeItem(at: pasta.appendingPathComponent(item))
        }
    }
}
