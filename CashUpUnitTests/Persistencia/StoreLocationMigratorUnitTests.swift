import XCTest
import SwiftData

@testable import CashUp

final class StoreLocationMigratorUnitTests: XCTestCase {

    private var raiz: URL!
    private var antigo: URL!
    private var grupo: URL!
    private let fm = FileManager.default
    private let data = Date.make(year: 2026, month: 3, day: 10)

    private struct FalhaSimulada: Error {}

    override func setUpWithError() throws {
        raiz = fm.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        let pastaAntiga = raiz.appendingPathComponent("AppSupport", isDirectory: true)
        let pastaGrupo = raiz.appendingPathComponent("Grupo/Library/Application Support", isDirectory: true)
        try fm.createDirectory(at: pastaAntiga, withIntermediateDirectories: true)
        antigo = pastaAntiga.appendingPathComponent("default.store")
        grupo = pastaGrupo.appendingPathComponent("default.store")
    }

    override func tearDownWithError() throws {
        try? fm.removeItem(at: raiz)
    }

    // MARK: - Fluxo completo

    func testUpgradeComStoreNoLocalAntigoPreservaDados() throws {
        try criarStore(em: antigo, transacoes: 2)

        let container = try CashUpPersistence.makeContainer(localizacao: StoreLocalizacao(antigo: antigo, grupo: grupo))

        XCTAssertEqual(try contar(container), 2)
        let contexto = ModelContext(container)
        let total = try contexto.fetch(FetchDescriptor<ExpenseModel>()).reduce(0) { $0 + $1.amountInCents }
        XCTAssertEqual(total, 2_500)
        XCTAssertTrue(fm.fileExists(atPath: grupo.path))
    }

    func testAntigoESeusAuxiliaresSaoApagadosDepoisDeAbrir() throws {
        try criarStore(em: antigo, transacoes: 1)
        try escrever("wal", em: auxiliar(antigo, "-wal"))
        try escrever("shm", em: auxiliar(antigo, "-shm"))
        let migrador = StoreLocationMigrator(antigo: antigo, grupo: grupo)

        XCTAssertEqual(try migrador.prepararGrupo(), .copiado)
        // Antes de o container novo abrir, o antigo continua inteiro.
        XCTAssertTrue(fm.fileExists(atPath: antigo.path))
        XCTAssertTrue(fm.fileExists(atPath: auxiliar(antigo, "-wal").path))

        migrador.concluirMigracao()

        XCTAssertFalse(fm.fileExists(atPath: antigo.path))
        XCTAssertFalse(fm.fileExists(atPath: auxiliar(antigo, "-wal").path))
        XCTAssertFalse(fm.fileExists(atPath: auxiliar(antigo, "-shm").path))
        XCTAssertTrue(fm.fileExists(atPath: auxiliar(grupo, "-wal").path))
        XCTAssertTrue(fm.fileExists(atPath: auxiliar(grupo, "-shm").path))
        XCTAssertEqual(try residuosNaPastaDoGrupo(), [], "Sem marcador nem pasta temporária depois de concluir")
    }

    func testReabrirNaoCopiaDeNovo() throws {
        try criarStore(em: antigo, transacoes: 2)
        let localizacao = StoreLocalizacao(antigo: antigo, grupo: grupo)
        do {
            let container = try CashUpPersistence.makeContainer(localizacao: localizacao)
            let contexto = ModelContext(container)
            contexto.insert(ExpenseModel(amountInCents: 500, date: data, expenseDescription: "Novo"))
            try contexto.save()
        }

        // Um novo store aparece no local antigo (ex.: build antigo reinstalado): não pode ser copiado por cima.
        try criarStore(em: antigo, transacoes: 7)
        XCTAssertEqual(try StoreLocationMigrator(antigo: antigo, grupo: grupo).prepararGrupo(), .grupoJaExistia)
        let reaberto = try CashUpPersistence.makeContainer(localizacao: localizacao)

        XCTAssertEqual(try contar(reaberto), 3)
        XCTAssertTrue(fm.fileExists(atPath: antigo.path), "Sem marcador de migração, o antigo não é tocado")
    }

    func testGrupoJaExisteEAntigoExisteNaoSobrescreve() throws {
        try criarStore(em: grupo, transacoes: 4)
        try criarStore(em: antigo, transacoes: 1)
        let bytesDoGrupo = try Data(contentsOf: grupo)

        let resultado = try StoreLocationMigrator(antigo: antigo, grupo: grupo).prepararGrupo()

        XCTAssertEqual(resultado, .grupoJaExistia)
        XCTAssertEqual(try Data(contentsOf: grupo), bytesDoGrupo)
        let container = try CashUpPersistence.makeContainer(localizacao: StoreLocalizacao(antigo: antigo, grupo: grupo))
        XCTAssertEqual(try contar(container), 4)
        XCTAssertTrue(fm.fileExists(atPath: antigo.path))
    }

    func testInstalacaoLimpaNaoFazNada() throws {
        let migrador = StoreLocationMigrator(antigo: antigo, grupo: grupo)

        XCTAssertEqual(try migrador.prepararGrupo(), .semStoreAntigo)
        migrador.concluirMigracao()

        XCTAssertFalse(fm.fileExists(atPath: grupo.path))
        XCTAssertFalse(fm.fileExists(atPath: antigo.path))
        XCTAssertEqual(try residuosNaPastaDoGrupo(), [])

        // Abrir o app em instalação nova cria o store direto no grupo, nunca no local antigo.
        let container = try CashUpPersistence.makeContainer(localizacao: StoreLocalizacao(antigo: antigo, grupo: grupo))
        XCTAssertEqual(try contar(container), 0)
        XCTAssertTrue(fm.fileExists(atPath: grupo.path))
        XCTAssertFalse(fm.fileExists(atPath: antigo.path))
    }

    func testSemContainerDeGrupoUsaOLocalAntigoSemMoverNada() throws {
        try criarStore(em: antigo, transacoes: 2)

        let container = try CashUpPersistence.makeContainer(localizacao: StoreLocalizacao(antigo: antigo, grupo: nil))

        XCTAssertEqual(try contar(container), 2)
        XCTAssertTrue(fm.fileExists(atPath: antigo.path))
        XCTAssertFalse(fm.fileExists(atPath: grupo.path))
    }

    // MARK: - Falhas

    func testCopiaInterrompidaNaoDeixaStoreInvalidoEPermiteNovaTentativa() throws {
        try escrever("store", em: antigo)
        try escrever("wal", em: auxiliar(antigo, "-wal"))
        try escrever("shm", em: auxiliar(antigo, "-shm"))
        var chamadas = 0
        let operacoes = StoreLocationMigrator.Operacoes(
            copiar: { origem, destino in
                chamadas += 1
                if chamadas == 2 { throw FalhaSimulada() }
                try FileManager.default.copyItem(at: origem, to: destino)
            },
            mover: StoreLocationMigrator.Operacoes.padrao.mover
        )

        XCTAssertThrowsError(try StoreLocationMigrator(antigo: antigo, grupo: grupo, operacoes: operacoes).prepararGrupo())

        XCTAssertFalse(fm.fileExists(atPath: grupo.path))
        XCTAssertEqual(try residuosNaPastaDoGrupo(), [])
        XCTAssertTrue(fm.fileExists(atPath: antigo.path))

        XCTAssertEqual(try StoreLocationMigrator(antigo: antigo, grupo: grupo).prepararGrupo(), .copiado)
        XCTAssertEqual(try String(contentsOf: grupo, encoding: .utf8), "store")
        XCTAssertEqual(try String(contentsOf: auxiliar(grupo, "-wal"), encoding: .utf8), "wal")
    }

    func testInterrupcaoAoMoverOsArquivosLimpaOsAuxiliaresSoltos() throws {
        try escrever("store", em: antigo)
        try escrever("wal", em: auxiliar(antigo, "-wal"))
        // Os auxiliares já foram movidos quando o `.store` (último) falha.
        let operacoes = StoreLocationMigrator.Operacoes(
            copiar: StoreLocationMigrator.Operacoes.padrao.copiar,
            mover: { origem, destino in
                if destino.lastPathComponent == "default.store" { throw FalhaSimulada() }
                try FileManager.default.moveItem(at: origem, to: destino)
            }
        )

        XCTAssertThrowsError(try StoreLocationMigrator(antigo: antigo, grupo: grupo, operacoes: operacoes).prepararGrupo())

        XCTAssertFalse(fm.fileExists(atPath: grupo.path))
        XCTAssertFalse(fm.fileExists(atPath: auxiliar(grupo, "-wal").path), "Um -wal solto não pode ficar sem o .store")
        XCTAssertEqual(try residuosNaPastaDoGrupo(), [])
        XCTAssertTrue(fm.fileExists(atPath: antigo.path))
    }

    func testResiduosDeTentativaAnteriorSaoDescartados() throws {
        try criarStore(em: antigo, transacoes: 2)
        let pastaDoGrupo = grupo.deletingLastPathComponent()
        try fm.createDirectory(at: pastaDoGrupo.appendingPathComponent(".migracao-ABC"), withIntermediateDirectories: true)
        try escrever("lixo", em: auxiliar(grupo, "-wal"))
        try escrever("", em: URL(fileURLWithPath: grupo.path + ".migracao-pendente"))

        let container = try CashUpPersistence.makeContainer(localizacao: StoreLocalizacao(antigo: antigo, grupo: grupo))

        XCTAssertEqual(try contar(container), 2, "O -wal solto de uma tentativa anterior não pode ser aplicado ao store novo")
        XCTAssertEqual(try residuosNaPastaDoGrupo(), [])
    }

    func testFalhaNaCopiaAbreOAntigoSemPerderDadosETentaDeNovoDepois() throws {
        try criarStore(em: antigo, transacoes: 2)
        let localizacao = StoreLocalizacao(antigo: antigo, grupo: grupo)
        let operacoes = StoreLocationMigrator.Operacoes(copiar: { _, _ in throw FalhaSimulada() }, mover: StoreLocationMigrator.Operacoes.padrao.mover)

        do {
            let container = try CashUpPersistence.makeContainer(localizacao: localizacao, operacoes: operacoes)
            XCTAssertEqual(try contar(container), 2)
            let contexto = ModelContext(container)
            contexto.insert(ExpenseModel(amountInCents: 500, date: data, expenseDescription: "Durante a falha"))
            try contexto.save()
        }
        XCTAssertFalse(fm.fileExists(atPath: grupo.path))

        // Na abertura seguinte a cópia funciona e leva também o que foi gravado no meio-tempo.
        let container = try CashUpPersistence.makeContainer(localizacao: localizacao)
        XCTAssertEqual(try contar(container), 3)
        XCTAssertFalse(fm.fileExists(atPath: antigo.path))
    }

    func testFalhaNaAberturaDoNovoMantemOAntigo() throws {
        // Um arquivo que não é SQLite copia normalmente, mas o container não abre.
        try escrever("isto não é um store", em: antigo)
        let localizacao = StoreLocalizacao(antigo: antigo, grupo: grupo)

        XCTAssertThrowsError(try CashUpPersistence.makeContainer(localizacao: localizacao))

        XCTAssertTrue(fm.fileExists(atPath: antigo.path), "Container novo não abriu: o antigo não pode ser apagado")
        XCTAssertEqual(try String(contentsOf: antigo, encoding: .utf8), "isto não é um store")
    }

    func testEncerradoAposAbrirTerminaALimpezaNaProximaAbertura() throws {
        try criarStore(em: antigo, transacoes: 2)
        let localizacao = StoreLocalizacao(antigo: antigo, grupo: grupo)
        // Simula o app morto depois de copiar e antes de apagar o antigo.
        XCTAssertEqual(try StoreLocationMigrator(antigo: antigo, grupo: grupo).prepararGrupo(), .copiado)
        XCTAssertTrue(fm.fileExists(atPath: antigo.path))

        let container = try CashUpPersistence.makeContainer(localizacao: localizacao)

        XCTAssertEqual(try contar(container), 2)
        XCTAssertFalse(fm.fileExists(atPath: antigo.path))
        XCTAssertEqual(try residuosNaPastaDoGrupo(), [])
    }

    // MARK: - Localização padrão

    func testLocalizacaoPadraoDoGrupoCoincideComGroupContainer() throws {
        let localizacao = CashUpPersistence.localizacaoPadrao()
        guard let urlDoGrupo = localizacao.grupo else {
            throw XCTSkip("Container do App Group indisponível neste ambiente (sem entitlement/assinatura)")
        }
        let base = try XCTUnwrap(fm.containerURL(forSecurityApplicationGroupIdentifier: CashUpAppGroup.identificador))
        XCTAssertTrue(urlDoGrupo.resolvingSymlinksInPath().path.hasPrefix(base.resolvingSymlinksInPath().path), "grupo=\(urlDoGrupo.path) base=\(base.path)")
        XCTAssertNotEqual(urlDoGrupo, localizacao.antigo)
        XCTAssertEqual(localizacao.antigo.deletingLastPathComponent().lastPathComponent, "Application Support")
        XCTAssertFalse(localizacao.antigo.path.hasPrefix(base.path), "O store antigo mora no container do app, não no do grupo")
    }

    // MARK: - Helpers

    private func criarStore(em url: URL, transacoes: Int) throws {
        try fm.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let container = try CashUpPersistence.makeContainer(url: url)
        let contexto = ModelContext(container)
        for indice in 0..<transacoes {
            contexto.insert(ExpenseModel(amountInCents: Int64(1_000 + indice * 500), date: data, expenseDescription: "Item \(indice)"))
        }
        try contexto.save()
    }

    private func contar(_ container: ModelContainer) throws -> Int {
        try ModelContext(container).fetchCount(FetchDescriptor<ExpenseModel>())
    }

    private func escrever(_ texto: String, em url: URL) throws {
        try fm.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try texto.write(to: url, atomically: true, encoding: .utf8)
    }

    private func auxiliar(_ url: URL, _ sufixo: String) -> URL {
        URL(fileURLWithPath: url.path + sufixo)
    }

    /// Marcadores e pastas temporárias de migração que sobraram ao lado do store do grupo.
    private func residuosNaPastaDoGrupo() throws -> [String] {
        let pasta = grupo.deletingLastPathComponent()
        guard fm.fileExists(atPath: pasta.path) else { return [] }
        return try fm.contentsOfDirectory(atPath: pasta.path).filter { $0.hasPrefix(".migracao-") || $0.hasSuffix(".migracao-pendente") }
    }
}
