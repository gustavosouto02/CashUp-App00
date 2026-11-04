import XCTest
import SwiftData

@testable import CashUp

final class StoreLocationMigratorUnitTests: XCTestCase {

    private var raiz: URL!
    private var antigo: URL!
    private var grupo: URL!
    private var sentinela: URL!
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
        sentinela = pastaAntiga.appendingPathComponent("default.store.no-app-group")
    }

    override func tearDownWithError() throws {
        // Testes que tiram a permissão de escrita da pasta antiga a restauram, mas garante-se aqui para a limpeza.
        try? fm.setAttributes([.posixPermissions: 0o755], ofItemAtPath: antigo.deletingLastPathComponent().path)
        try? fm.removeItem(at: raiz)
    }

    // MARK: - Fluxo completo

    func testStoreNaVersaoAtualNoLocalAntigoVaiParaOGrupoComOsMesmosDados() throws {
        try criarStore(em: antigo, transacoes: 2)

        let container = try CashUpPersistence.makeContainer(localizacao: StoreLocalizacao(antigo: antigo, grupo: grupo))

        XCTAssertEqual(try contar(container), 2)
        let contexto = ModelContext(container)
        let total = try contexto.fetch(FetchDescriptor<ExpenseModel>()).reduce(0) { $0 + $1.amountInCents }
        XCTAssertEqual(total, 2_500)
        XCTAssertTrue(fm.fileExists(atPath: grupo.path))
    }

    func testMigradorCopiaOsAuxiliaresEApagaOAntigoSoAoConcluir() throws {
        // Nível do migrador, com arquivos sintéticos e sem abrir container: o fluxo com container está nos testes de `makeContainer`.
        try escrever("store", em: antigo)
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
        // Resíduo realista: um WAL válido (de outro store) e um diretório de dados externos soltos no grupo, mais marcador e pasta temporária.
        let walValido = try gerarWalValido()
        let pastaDoGrupo = grupo.deletingLastPathComponent()
        try fm.createDirectory(at: pastaDoGrupo.appendingPathComponent(".migracao-ABC"), withIntermediateDirectories: true)
        try walValido.write(to: auxiliar(grupo, "-wal"))
        try escrever("lixo", em: suporte(grupo).appendingPathComponent("_EXTERNAL_DATA/velho"))
        try escrever("", em: URL(fileURLWithPath: grupo.path + ".migracao-pendente"))
        let migrador = StoreLocationMigrator(antigo: antigo, grupo: grupo)

        XCTAssertEqual(try migrador.prepararGrupo(), .copiado, "A cópia ocorreu nesta tentativa; os resíduos não foram tratados como um store do grupo")

        // O store antigo pode ter o próprio `-wal`, que é copiado; o que não pode sobrar é o WAL velho do resíduo.
        XCTAssertNotEqual(try? Data(contentsOf: auxiliar(grupo, "-wal")), walValido, "O WAL velho não pode sobrar para ser aplicado ao store novo")
        XCTAssertFalse(fm.fileExists(atPath: suporte(grupo).path))
        XCTAssertFalse(fm.fileExists(atPath: pastaDoGrupo.appendingPathComponent(".migracao-ABC").path))
        let container = try CashUpPersistence.makeContainer(url: grupo)
        XCTAssertEqual(try contar(container), 2)
        migrador.concluirMigracao()
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

    func testFalhaNaAberturaDoNovoMantemOAntigoEDescartaACopia() throws {
        // Um arquivo que não é SQLite copia normalmente, mas o container não abre.
        try escrever("isto não é um store", em: antigo)
        try escrever("dado externo", em: suporte(antigo).appendingPathComponent("_EXTERNAL_DATA/x"))
        let localizacao = StoreLocalizacao(antigo: antigo, grupo: grupo)

        XCTAssertThrowsError(try CashUpPersistence.makeContainer(localizacao: localizacao))

        XCTAssertTrue(fm.fileExists(atPath: antigo.path), "Container novo não abriu: o antigo não pode ser apagado")
        XCTAssertEqual(try String(contentsOf: antigo, encoding: .utf8), "isto não é um store")
        XCTAssertTrue(fm.fileExists(atPath: suporte(antigo).appendingPathComponent("_EXTERNAL_DATA/x").path))
        // A cópia que não abriu (possivelmente meio migrada) não é reaproveitada: o grupo volta a ficar sem nada.
        XCTAssertFalse(fm.fileExists(atPath: grupo.path))
        XCTAssertFalse(fm.fileExists(atPath: suporte(grupo).path))
        XCTAssertEqual(try residuosNaPastaDoGrupo(), [])

        // Na abertura seguinte a cópia é refeita a partir do original.
        XCTAssertEqual(try StoreLocationMigrator(antigo: antigo, grupo: grupo).prepararGrupo(), .copiado)
        XCTAssertEqual(try String(contentsOf: grupo, encoding: .utf8), "isto não é um store")
    }

    func testEncerradoAposCopiarENuncaAbertoTerminaNaProximaAbertura() throws {
        try criarStore(em: antigo, transacoes: 2)
        let localizacao = StoreLocalizacao(antigo: antigo, grupo: grupo)
        // Simula o app morto depois de copiar e antes de abrir o container novo (marcador "pendente").
        XCTAssertEqual(try StoreLocationMigrator(antigo: antigo, grupo: grupo).prepararGrupo(), .copiado)
        XCTAssertTrue(fm.fileExists(atPath: antigo.path))

        let container = try CashUpPersistence.makeContainer(localizacao: localizacao)

        XCTAssertEqual(try contar(container), 2)
        XCTAssertFalse(fm.fileExists(atPath: antigo.path))
        XCTAssertEqual(try residuosNaPastaDoGrupo(), [])
    }

    func testEncerradoAposAbrirRetomaALimpezaAPartirDoMarcadorDeLimpeza() throws {
        try criarStore(em: antigo, transacoes: 2)
        let localizacao = StoreLocalizacao(antigo: antigo, grupo: grupo)
        XCTAssertEqual(try StoreLocationMigrator(antigo: antigo, grupo: grupo).prepararGrupo(), .copiado)
        // Simula o app morto depois de abrir o grupo e renomear o marcador, no meio de apagar o antigo: sobrou só o `.store`.
        try fm.moveItem(at: URL(fileURLWithPath: grupo.path + ".migracao-pendente"), to: URL(fileURLWithPath: grupo.path + ".migracao-limpeza"))
        try? fm.removeItem(at: auxiliar(antigo, "-shm"))

        let container = try CashUpPersistence.makeContainer(localizacao: localizacao)

        XCTAssertEqual(try contar(container), 2)
        XCTAssertFalse(fm.fileExists(atPath: antigo.path))
        XCTAssertEqual(try residuosNaPastaDoGrupo(), [])
    }

    func testFalhaAoApagarOAntigoMantemOMarcadorEARetomaDepois() throws {
        try criarStore(em: antigo, transacoes: 2)
        let localizacao = StoreLocalizacao(antigo: antigo, grupo: grupo)
        let pastaAntiga = antigo.deletingLastPathComponent()
        // Sem permissão de escrita na pasta, o `removeItem` do antigo falha.
        try fm.setAttributes([.posixPermissions: 0o555], ofItemAtPath: pastaAntiga.path)

        _ = try CashUpPersistence.makeContainer(localizacao: localizacao)

        XCTAssertTrue(fm.fileExists(atPath: antigo.path))
        XCTAssertTrue(fm.fileExists(atPath: grupo.path + ".migracao-limpeza"), "Sobrou arquivo do antigo: o marcador de limpeza fica")

        try fm.setAttributes([.posixPermissions: 0o755], ofItemAtPath: pastaAntiga.path)
        let container = try CashUpPersistence.makeContainer(localizacao: localizacao)

        XCTAssertEqual(try contar(container), 2)
        XCTAssertFalse(fm.fileExists(atPath: antigo.path))
        XCTAssertEqual(try residuosNaPastaDoGrupo(), [])
    }

    func testAntigoAlteradoDepoisDaCopiaNaoEApagado() throws {
        try criarStore(em: antigo, transacoes: 2)
        let migrador = StoreLocationMigrator(antigo: antigo, grupo: grupo)
        XCTAssertEqual(try migrador.prepararGrupo(), .copiado)
        // Algo gravou no store antigo depois da cópia (ex.: um build sem o grupo abriu o antigo).
        try fm.setAttributes([.modificationDate: Date().addingTimeInterval(120)], ofItemAtPath: antigo.path)

        migrador.concluirMigracao()

        XCTAssertTrue(fm.fileExists(atPath: antigo.path), "Dados gravados depois da cópia não podem ser apagados")
        XCTAssertEqual(try residuosNaPastaDoGrupo(), [], "O marcador sai para não repetir a decisão a cada abertura")
    }

    func testWalDoAntigoAlteradoDepoisDaCopiaNaoEApagaOAntigo() throws {
        try escrever("store", em: antigo)
        let migrador = StoreLocationMigrator(antigo: antigo, grupo: grupo)
        XCTAssertEqual(try migrador.prepararGrupo(), .copiado)
        try escrever("gravado depois", em: auxiliar(antigo, "-wal"))
        try fm.setAttributes([.modificationDate: Date().addingTimeInterval(120)], ofItemAtPath: auxiliar(antigo, "-wal").path)

        migrador.concluirMigracao()

        XCTAssertTrue(fm.fileExists(atPath: antigo.path))
        XCTAssertTrue(fm.fileExists(atPath: auxiliar(antigo, "-wal").path))
    }

    func testGrupoIndisponivelDepoisDeMigrarNaoCriaStoreVazio() throws {
        try criarStore(em: antigo, transacoes: 2)
        _ = try CashUpPersistence.makeContainer(localizacao: StoreLocalizacao(antigo: antigo, grupo: grupo, sentinela: sentinela))
        XCTAssertTrue(fm.fileExists(atPath: sentinela.path), "A primeira abertura bem-sucedida no grupo grava a sentinela")
        XCTAssertFalse(fm.fileExists(atPath: antigo.path))

        // O grupo some (build sem entitlement, por exemplo): não pode nascer um store vazio no local antigo.
        XCTAssertThrowsError(try CashUpPersistence.makeContainer(localizacao: StoreLocalizacao(antigo: antigo, grupo: nil, sentinela: sentinela))) { erro in
            XCTAssertEqual(erro as? StoreLocalizacaoErro, .grupoIndisponivel)
        }
        XCTAssertFalse(fm.fileExists(atPath: antigo.path), "Nenhum store vazio criado no local antigo")

        // Com o grupo de volta, os dados continuam lá.
        let container = try CashUpPersistence.makeContainer(localizacao: StoreLocalizacao(antigo: antigo, grupo: grupo, sentinela: sentinela))
        XCTAssertEqual(try contar(container), 2)
    }

    func testSemSentinelaESemGrupoSegueNoLocalAntigo() throws {
        // Aparelho que nunca usou o grupo (sem entitlement desde sempre): abre o antigo normalmente.
        let container = try CashUpPersistence.makeContainer(localizacao: StoreLocalizacao(antigo: antigo, grupo: nil, sentinela: sentinela))

        XCTAssertEqual(try contar(container), 0)
        XCTAssertTrue(fm.fileExists(atPath: antigo.path))
        XCTAssertFalse(fm.fileExists(atPath: sentinela.path))
    }

    func testInstalacaoLimpaNoGrupoTambemGravaASentinela() throws {
        _ = try CashUpPersistence.makeContainer(localizacao: StoreLocalizacao(antigo: antigo, grupo: grupo, sentinela: sentinela))

        XCTAssertTrue(fm.fileExists(atPath: sentinela.path))
    }

    // MARK: - Dados externos do Core Data

    func testDiretorioDeDadosExternosAcompanhaOStore() throws {
        try criarStore(em: antigo, transacoes: 1)
        try escrever("blob", em: suporte(antigo).appendingPathComponent("_EXTERNAL_DATA/x"))
        var destinos: [String] = []
        let operacoes = StoreLocationMigrator.Operacoes(
            copiar: StoreLocationMigrator.Operacoes.padrao.copiar,
            mover: { origem, destino in
                destinos.append(destino.lastPathComponent)
                try FileManager.default.moveItem(at: origem, to: destino)
            }
        )
        let migrador = StoreLocationMigrator(antigo: antigo, grupo: grupo, operacoes: operacoes)

        XCTAssertEqual(try migrador.prepararGrupo(), .copiado)

        XCTAssertEqual(try String(contentsOf: suporte(grupo).appendingPathComponent("_EXTERNAL_DATA/x"), encoding: .utf8), "blob")
        XCTAssertEqual(destinos.last, "default.store", "O `.store` é o último a ser movido (ponto de commit)")
        XCTAssertTrue(destinos.contains(".default_SUPPORT"))
        XCTAssertTrue(fm.fileExists(atPath: suporte(antigo).path), "Antes de concluir, o antigo continua inteiro")

        migrador.concluirMigracao()

        XCTAssertFalse(fm.fileExists(atPath: suporte(antigo).path))
        XCTAssertFalse(fm.fileExists(atPath: antigo.path))
        XCTAssertTrue(fm.fileExists(atPath: suporte(grupo).appendingPathComponent("_EXTERNAL_DATA/x").path))
        XCTAssertEqual(try residuosNaPastaDoGrupo(), [])
    }

    func testDestinoDosAuxiliaresDerivaDoNomeDoArquivoDoGrupo() throws {
        let outroGrupo = grupo.deletingLastPathComponent().appendingPathComponent("CashUp.store")
        try escrever("store", em: antigo)
        try escrever("wal", em: auxiliar(antigo, "-wal"))
        try escrever("shm", em: auxiliar(antigo, "-shm"))
        try escrever("blob", em: suporte(antigo).appendingPathComponent("_EXTERNAL_DATA/x"))

        XCTAssertEqual(try StoreLocationMigrator(antigo: antigo, grupo: outroGrupo).prepararGrupo(), .copiado)

        XCTAssertEqual(try String(contentsOf: auxiliar(outroGrupo, "-wal"), encoding: .utf8), "wal")
        XCTAssertEqual(try String(contentsOf: auxiliar(outroGrupo, "-shm"), encoding: .utf8), "shm")
        XCTAssertTrue(fm.fileExists(atPath: suporte(outroGrupo).appendingPathComponent("_EXTERNAL_DATA/x").path))
        XCTAssertEqual(suporte(outroGrupo).lastPathComponent, ".CashUp_SUPPORT")
        XCTAssertFalse(fm.fileExists(atPath: auxiliar(grupo, "-wal").path), "Nada com o nome do antigo no grupo")
    }

    func testPastaTemporariaVaziaTambemELimpaQuandoOGrupoJaExiste() throws {
        try criarStore(em: grupo, transacoes: 1)
        let temporaria = grupo.deletingLastPathComponent().appendingPathComponent(".migracao-VAZIA")
        try fm.createDirectory(at: temporaria, withIntermediateDirectories: true)

        XCTAssertEqual(try StoreLocationMigrator(antigo: antigo, grupo: grupo).prepararGrupo(), .grupoJaExistia)

        XCTAssertFalse(fm.fileExists(atPath: temporaria.path))
    }

    // MARK: - Upgrade a partir do store da 1.5

    func testUpgradeDoStoreDaVersao15NoLocalAntigoMigraOSchemaEMudaDeLocal() throws {
        try FixtureStoreV1.criar(em: antigo)

        let container = try CashUpPersistence.makeContainer(localizacao: StoreLocalizacao(antigo: antigo, grupo: grupo, sentinela: sentinela))

        let contexto = ModelContext(container)
        let transacoes = try contexto.fetch(FetchDescriptor<ExpenseModel>())
        XCTAssertEqual(transacoes.count, 2)
        XCTAssertEqual(transacoes.reduce(0) { $0 + $1.amountInCents }, FixtureStoreV1.totalEmCentavos)
        XCTAssertEqual(transacoes.first { $0.id == FixtureStoreV1.idRecorrente }?.repetition?.excludedDates, [FixtureStoreV1.excluida])
        XCTAssertEqual(try contexto.fetch(FetchDescriptor<SubcategoriaPlanejadaModel>()).first?.valorPlanejadoCentavos, 30_000)
        XCTAssertTrue(transacoes.allSatisfy { $0.conta?.id == SeedIDs.idContaCarteira })
        XCTAssertTrue(fm.fileExists(atPath: grupo.path))
        XCTAssertFalse(fm.fileExists(atPath: antigo.path), "O store antigo é removido depois de o grupo abrir")
        XCTAssertEqual(try residuosNaPastaDoGrupo(), [])
    }

    // MARK: - Localização padrão

    func testLocalizacaoPadraoDoGrupoCoincideComGroupContainer() throws {
        let localizacao = CashUpPersistence.localizacaoPadrao()
        guard let urlDoGrupo = localizacao.grupo else {
            throw XCTSkip("Container do App Group indisponível neste ambiente (build sem o entitlement)")
        }
        let base = try XCTUnwrap(fm.containerURL(forSecurityApplicationGroupIdentifier: CashUpAppGroup.identificador))
        XCTAssertTrue(urlDoGrupo.resolvingSymlinksInPath().path.hasPrefix(base.resolvingSymlinksInPath().path), "grupo=\(urlDoGrupo.path) base=\(base.path)")
        XCTAssertNotEqual(urlDoGrupo, localizacao.antigo)
        XCTAssertEqual(localizacao.antigo.deletingLastPathComponent().lastPathComponent, "Application Support")
        XCTAssertFalse(localizacao.antigo.path.hasPrefix(base.path), "O store antigo mora no container do app, não no do grupo")
        let sentinelaPadrao = try XCTUnwrap(localizacao.sentinela)
        XCTAssertFalse(sentinelaPadrao.path.hasPrefix(base.path), "A sentinela mora no container do app, fora do grupo")
        XCTAssertEqual(sentinelaPadrao.deletingLastPathComponent(), localizacao.antigo.deletingLastPathComponent())
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

    /// Diretório de dados externos do Core Data ao lado do store (`.default_SUPPORT`).
    private func suporte(_ url: URL) -> URL {
        url.deletingLastPathComponent().appendingPathComponent(".\(url.deletingPathExtension().lastPathComponent)_SUPPORT", isDirectory: true)
    }

    /// Bytes de um `-wal` real, copiados de um store aberto (o WAL só existe enquanto o container está aberto).
    private func gerarWalValido() throws -> Data {
        let url = raiz.appendingPathComponent("Wal/velho.store")
        let container = try CashUpPersistence.makeContainer(url: url)
        let contexto = ModelContext(container)
        contexto.insert(ExpenseModel(amountInCents: 1, date: data, expenseDescription: "Velho"))
        try contexto.save()
        let bytes = try Data(contentsOf: auxiliar(url, "-wal"))
        withExtendedLifetime(container) {}
        XCTAssertGreaterThan(bytes.count, 32, "Um WAL válido tem mais que o cabeçalho de 32 bytes")
        return bytes
    }

    /// Marcadores e pastas temporárias de migração que sobraram ao lado do store do grupo.
    private func residuosNaPastaDoGrupo() throws -> [String] {
        let pasta = grupo.deletingLastPathComponent()
        guard fm.fileExists(atPath: pasta.path) else { return [] }
        return try fm.contentsOfDirectory(atPath: pasta.path).filter { $0.hasPrefix(".migracao-") || $0.hasSuffix(".migracao-pendente") || $0.hasSuffix(".migracao-limpeza") }
    }
}
