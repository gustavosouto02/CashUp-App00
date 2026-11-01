import XCTest
import SwiftData

@testable import CashUp

final class MigracaoUnitTests: XCTestCase {

    private var diretorio: URL!
    private var storeURL: URL!

    private let idCategoria = UUID()
    private let idSubcategoria = UUID()
    private let idRecorrente = UUID()
    private let idReceita = UUID()
    private let idPlanejada = UUID()
    private let marco = Date.make(year: 2026, month: 3, day: 10)
    private let excluida = Date.make(year: 2026, month: 5, day: 10)

    override func setUpWithError() throws {
        diretorio = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: diretorio, withIntermediateDirectories: true)
        storeURL = diretorio.appendingPathComponent("CashUp.store")
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: diretorio)
    }

    func testStoreV1AbreNaVersaoAtualComOsMesmosDados() throws {
        try criarStoreV1()

        let contexto = ModelContext(try CashUpPersistence.makeContainer(url: storeURL))

        XCTAssertEqual(try contexto.fetchCount(FetchDescriptor<CategoriaModel>()), 1)
        XCTAssertEqual(try contexto.fetchCount(FetchDescriptor<SubcategoriaModel>()), 1)
        XCTAssertEqual(try contexto.fetchCount(FetchDescriptor<ExpenseModel>()), 2)
        XCTAssertEqual(try contexto.fetchCount(FetchDescriptor<CategoriaPlanejadaModel>()), 1)
        XCTAssertEqual(try contexto.fetchCount(FetchDescriptor<SubcategoriaPlanejadaModel>()), 1)

        let transacoes = try contexto.fetch(FetchDescriptor<ExpenseModel>())
        XCTAssertEqual(transacoes.reduce(0) { $0 + $1.amountInCents }, 184_990)
    }

    func testMigracaoPreservaRecorrenciaERelacionamentos() throws {
        try criarStoreV1()

        let contexto = ModelContext(try CashUpPersistence.makeContainer(url: storeURL))
        let recorrente = try XCTUnwrap(try contexto.fetch(FetchDescriptor<ExpenseModel>()).first { $0.id == idRecorrente })

        XCTAssertEqual(recorrente.repetition?.repeatOption, .mensalmente)
        XCTAssertEqual(recorrente.repetition?.excludedDates, [excluida])
        XCTAssertEqual(recorrente.categoria?.id, idCategoria)
        XCTAssertEqual(recorrente.subcategoria?.id, idSubcategoria)
        XCTAssertEqual(recorrente.subcategoria?.usageCount, 3)
    }

    func testMigracaoPreencheAsInversasDeTransacoes() throws {
        try criarStoreV1()

        let contexto = ModelContext(try CashUpPersistence.makeContainer(url: storeURL))
        let categoria = try XCTUnwrap(try contexto.fetch(FetchDescriptor<CategoriaModel>()).first)
        let subcategoria = try XCTUnwrap(try contexto.fetch(FetchDescriptor<SubcategoriaModel>()).first)

        XCTAssertEqual(categoria.transacoes?.count, 2)
        XCTAssertEqual(subcategoria.transacoes?.count, 2)
    }

    func testMigracaoDaUmaInstanciaIDPropriaACadaRegistro() throws {
        try criarStoreV1()

        let contexto = ModelContext(try CashUpPersistence.makeContainer(url: storeURL))
        let transacoes = try contexto.fetch(FetchDescriptor<ExpenseModel>())
        let categorias = try contexto.fetch(FetchDescriptor<CategoriaModel>())
        let subcategorias = try contexto.fetch(FetchDescriptor<SubcategoriaModel>())
        let planejamentos = try contexto.fetch(FetchDescriptor<CategoriaPlanejadaModel>())
        let itensPlanejados = try contexto.fetch(FetchDescriptor<SubcategoriaPlanejadaModel>())

        let instancias = transacoes.map(\.instanciaID)
            + categorias.map(\.instanciaID)
            + subcategorias.map(\.instanciaID)
            + planejamentos.map(\.instanciaID)
            + itensPlanejados.map(\.instanciaID)
        XCTAssertEqual(instancias.count, 6)
        XCTAssertEqual(Set(instancias).count, instancias.count, "Cada registro migrado tem o próprio instanciaID")

        XCTAssertTrue(transacoes.allSatisfy { $0.criadoEm == .distantPast })
        XCTAssertTrue(categorias.allSatisfy { $0.criadoEm == .distantPast && $0.atualizadoEm == .distantPast })
        XCTAssertTrue(subcategorias.allSatisfy { $0.criadoEm == .distantPast && $0.atualizadoEm == .distantPast })
        XCTAssertTrue(planejamentos.allSatisfy { $0.criadoEm == .distantPast })
        XCTAssertTrue(itensPlanejados.allSatisfy { $0.criadoEm == .distantPast && $0.atualizadoEm == .distantPast })
        XCTAssertEqual(try contexto.fetchCount(FetchDescriptor<SeedRemocaoModel>()), 0)
    }

    func testMigracaoPreservaPlanejamento() throws {
        try criarStoreV1()

        let contexto = ModelContext(try CashUpPersistence.makeContainer(url: storeURL))
        let planejada = try XCTUnwrap(try contexto.fetch(FetchDescriptor<CategoriaPlanejadaModel>()).first)

        XCTAssertEqual(planejada.id, idPlanejada)
        XCTAssertEqual(planejada.mesAno, marco.startOfMonth())
        XCTAssertEqual(planejada.categoriaOriginal?.id, idCategoria)
        XCTAssertEqual(planejada.valorTotalPlanejado, 30_000)
        XCTAssertEqual(planejada.subcategoriasPlanejadas?.first?.subcategoriaOriginal?.id, idSubcategoria)
    }

    func testStoreAtualReabreSemPerderDados() throws {
        try criarStoreV1()

        do {
            let contexto = ModelContext(try CashUpPersistence.makeContainer(url: storeURL))
            contexto.insert(ExpenseModel(amountInCents: 1000, date: marco, expenseDescription: "Café"))
            try contexto.save()
        }

        let contexto = ModelContext(try CashUpPersistence.makeContainer(url: storeURL))
        XCTAssertEqual(try contexto.fetchCount(FetchDescriptor<ExpenseModel>()), 3)
    }

    func testMigracaoCentavosExatos() throws {
        try criarStoreV1()

        let contexto = ModelContext(try CashUpPersistence.makeContainer(url: storeURL))
        let transacoes = try contexto.fetch(FetchDescriptor<ExpenseModel>())

        XCTAssertEqual(transacoes.first { $0.id == idRecorrente }?.amountInCents, 4990)
        XCTAssertEqual(transacoes.first { $0.id == idReceita }?.amountInCents, 180_000)
        XCTAssertEqual(try contexto.fetch(FetchDescriptor<SubcategoriaPlanejadaModel>()).first?.valorPlanejadoCentavos, 30_000)
    }

    @MainActor
    func testTotalDoMesDaFixtureIdenticoCentavoPorCentavoAntesEDepoisDaMigracao() throws {
        let valores = valoresDeDuasCasas
        try criarStoreV3(valores: valores)

        // Antes: o total que o app mostrava na V3, somando os `Double` do próprio store (`(soma * 100).rounded()`).
        let esperadoEmCentavos = try somaEmCentavosDoStoreV3()
        // Número fixado de propósito: 1.235.836,76 (dez vezes 0,1 em Double somariam 0,9999999999999999).
        XCTAssertEqual(esperadoEmCentavos, 123_583_676)

        let contexto = ModelContext(try CashUpPersistence.makeContainer(url: storeURL))
        let transacoes = try contexto.fetch(FetchDescriptor<ExpenseModel>())

        XCTAssertEqual(transacoes.count, valores.count)
        XCTAssertEqual(transacoes.reduce(0) { $0 + $1.amountInCents }, esperadoEmCentavos)

        let totalDoMes = ExpensesViewModel(modelContext: contexto).totalExpense(in: marco)
        XCTAssertEqual(totalDoMes, esperadoEmCentavos)
    }

    /// Abre o store com o `SchemaV3` (sem migrar) e soma os `Double` de reais das transações, como a V3 fazia.
    private func somaEmCentavosDoStoreV3() throws -> Int64 {
        let schema = Schema(versionedSchema: SchemaV3.self)
        let container = try ModelContainer(for: schema, configurations: ModelConfiguration(schema: schema, url: storeURL))
        let soma = try ModelContext(container).fetch(FetchDescriptor<SchemaV3.ExpenseModel>()).reduce(0.0) { $0 + $1.amount }
        return Int64((soma * 100).rounded())
    }

    func testMigracaoArredondaCadaValorParaOCentavoMaisProximo() throws {
        let valores = valoresComRuidoDeDouble
        try criarStoreV3(valores: valores)

        let contexto = ModelContext(try CashUpPersistence.makeContainer(url: storeURL))
        let transacoes = try contexto.fetch(FetchDescriptor<ExpenseModel>())
        let porDescricao = Dictionary(uniqueKeysWithValues: transacoes.map { ($0.expenseDescription, $0.amountInCents) })

        let esperados: [Double: Int64] = [
            0.1: 10, 0.2: 20, 0.29: 29, 4.35: 435, 19.899999: 1990, 1.005: 101,
            2.675: 268, 1234567.89: 123_456_789, 0.07: 7, 8.2: 820, -3.2: -320,
        ]
        for (valor, centavos) in esperados {
            XCTAssertEqual(porDescricao["\(valor)"], centavos, "R$ \(valor) deveria virar \(centavos) centavos")
        }

        let planejados = try contexto.fetch(FetchDescriptor<SubcategoriaPlanejadaModel>())
        XCTAssertEqual(planejados.first?.valorPlanejadoCentavos, 1990)
    }

    func testConversaoZeraOLegadoEEhIdempotente() throws {
        try criarStoreV4(valores: [19.9, 0.07], centavosJaConvertidos: false)

        let container = try ModelContainer(
            for: Schema(versionedSchema: SchemaV4.self),
            configurations: ModelConfiguration(schema: Schema(versionedSchema: SchemaV4.self), url: storeURL)
        )
        let contexto = ModelContext(container)

        XCTAssertEqual(try CashUpMigrationPlan.converterValoresPendentesParaCentavos(em: contexto), 3)
        XCTAssertEqual(try CashUpMigrationPlan.converterValoresPendentesParaCentavos(em: contexto), 0)

        let transacoes = try contexto.fetch(FetchDescriptor<SchemaV4.ExpenseModel>())
        XCTAssertEqual(transacoes.reduce(0) { $0 + $1.amountInCents }, 1997)
        XCTAssertTrue(transacoes.allSatisfy { $0.amount == 0 })
        XCTAssertEqual(try contexto.fetch(FetchDescriptor<SchemaV4.SubcategoriaPlanejadaModel>()).first?.valorPlanejadoCentavos, 1990)
    }

    func testReabrirOStoreNaoMudaOsCentavos() throws {
        try criarStoreV1()

        for _ in 0..<2 {
            let contexto = ModelContext(try CashUpPersistence.makeContainer(url: storeURL))
            let transacoes = try contexto.fetch(FetchDescriptor<ExpenseModel>())
            XCTAssertEqual(transacoes.reduce(0) { $0 + $1.amountInCents }, 184_990)
        }
    }

    func testValorEditadoParaZeroNaoRessuscitaDepoisDaConversao() throws {
        try criarStoreV1()

        do {
            let contexto = ModelContext(try CashUpPersistence.makeContainer(url: storeURL))
            try contexto.fetch(FetchDescriptor<SubcategoriaPlanejadaModel>()).forEach { $0.valorPlanejadoCentavos = 0 }
            try contexto.save()
        }

        let contexto = ModelContext(try CashUpPersistence.makeContainer(url: storeURL))
        XCTAssertEqual(try contexto.fetch(FetchDescriptor<SubcategoriaPlanejadaModel>()).first?.valorPlanejadoCentavos, 0)
    }

    func testMigracaoDeValoresTruncariaSeFosseInt64DeValorVezes100() {
        // Documenta por que a migração não usa `Int64(valor * 100)`: 0,29 * 100 = 28,999999999999996.
        XCTAssertEqual(Int64(0.29 * 100), 28)
        XCTAssertEqual(Centavos.de(reais: 0.29), 29)
    }

    func testFalhaNoDidMigrateNaoCorrompeStore() throws {
        let valores = valoresComRuidoDeDouble
        try criarStoreV3(valores: valores)

        XCTAssertThrowsError(
            try ModelContainer(
                for: Schema(versionedSchema: SchemaV4.self),
                migrationPlan: PlanoComFalhaNoDidMigrate.self,
                configurations: ModelConfiguration(schema: Schema(versionedSchema: SchemaV4.self), url: storeURL)
            )
        )

        // O SwiftData já aplicou a mudança estrutural quando o `didMigrate` falha: o store passa a ser V4 com os centavos
        // zerados e o legado intacto. Reabrindo SEM migrar nada, é isso que se vê.
        do {
            let schemaV4 = Schema(versionedSchema: SchemaV4.self)
            let semReparo = try ModelContainer(
                for: schemaV4,
                migrationPlan: PlanoSemFalhaNoDidMigrate.self,
                configurations: ModelConfiguration(schema: schemaV4, url: storeURL)
            )
            let bruto = try ModelContext(semReparo).fetch(FetchDescriptor<SchemaV4.ExpenseModel>())
            XCTAssertEqual(bruto.count, valores.count)
            XCTAssertTrue(bruto.allSatisfy { $0.amountInCents == 0 }, "O store ficou V4 com os centavos zerados")
            XCTAssertTrue(bruto.allSatisfy { $0.amount != 0 }, "O legado em Double continua intacto")
        }

        // Por isso o `willMigrate` do estágio V4 → V5 termina a conversão em vez de abrir com totais zerados.
        let contexto = ModelContext(try CashUpPersistence.makeContainer(url: storeURL))
        let transacoes = try contexto.fetch(FetchDescriptor<ExpenseModel>())
        XCTAssertEqual(transacoes.count, valores.count)
        XCTAssertEqual(transacoes.first { $0.expenseDescription == "19.899999" }?.amountInCents, 1990)
        XCTAssertEqual(transacoes.first { $0.expenseDescription == "1234567.89" }?.amountInCents, 123_456_789)
        XCTAssertEqual(try contexto.fetch(FetchDescriptor<SubcategoriaPlanejadaModel>()).first?.valorPlanejadoCentavos, 1990)
    }

    // MARK: - V4 -> V5 (contas e tipo de lançamento)

    func testMigracaoCriaACarteiraELigaTodasAsTransacoes() throws {
        try criarStoreV1()

        let contexto = ModelContext(try CashUpPersistence.makeContainer(url: storeURL))
        let contas = try contexto.fetch(FetchDescriptor<ContaModel>())

        XCTAssertEqual(contas.count, 1)
        let carteira = try XCTUnwrap(contas.first)
        XCTAssertEqual(carteira.id, SeedIDs.idContaCarteira)
        XCTAssertEqual(carteira.nome, "Carteira")
        XCTAssertEqual(carteira.tipo, .carteira)
        XCTAssertEqual(carteira.saldoInicialCentavos, 0)

        let transacoes = try contexto.fetch(FetchDescriptor<ExpenseModel>())
        XCTAssertEqual(transacoes.count, 2)
        XCTAssertTrue(transacoes.allSatisfy { $0.conta?.id == SeedIDs.idContaCarteira })
        XCTAssertTrue(transacoes.allSatisfy { $0.contaDestino == nil })
        XCTAssertEqual(carteira.transacoes?.count, 2)
    }

    func testMigracaoDefineOTipoAPartirDeIsIncome() throws {
        try criarStoreV1()

        let contexto = ModelContext(try CashUpPersistence.makeContainer(url: storeURL))
        let transacoes = try contexto.fetch(FetchDescriptor<ExpenseModel>())

        XCTAssertEqual(transacoes.first { $0.id == idReceita }?.tipo, .receita)
        XCTAssertEqual(transacoes.first { $0.id == idReceita }?.tipoRaw, "receita")
        XCTAssertEqual(transacoes.first { $0.id == idRecorrente }?.tipo, .despesa)
        XCTAssertTrue(transacoes.allSatisfy { $0.isIncome == ($0.tipo == .receita) })
    }

    func testMigracaoCriaACarteiraMesmoSemTransacoes() throws {
        try criarStoreV4(valores: [], centavosJaConvertidos: true, comPlanejamento: false)

        let contexto = ModelContext(try CashUpPersistence.makeContainer(url: storeURL))

        XCTAssertEqual(try contexto.fetchCount(FetchDescriptor<ExpenseModel>()), 0)
        XCTAssertEqual(try contexto.fetch(FetchDescriptor<ContaModel>()).map(\.id), [SeedIDs.idContaCarteira])
    }

    @MainActor
    func testTotaisDaHomeNaoMudamDepoisDaMigracaoParaV5() throws {
        try criarStoreV1()

        let contexto = ModelContext(try CashUpPersistence.makeContainer(url: storeURL))
        let expenses = ExpensesViewModel(modelContext: contexto)
        let home = HomeViewModel(
            planningViewModel: PlanningViewModel(modelContext: contexto),
            expensesViewModel: expenses
        )
        home.currentMonth = marco
        home.updateCardData()

        XCTAssertEqual(home.totalSpentMonth, 4990)
        XCTAssertEqual(home.totalIncomeMonth, 180_000)
        XCTAssertEqual(expenses.totalExpense(in: marco), 4990)
        XCTAssertEqual(expenses.totalIncome(in: marco), 180_000)
    }

    func testStoreV4ComCentavosPendentesTerminaAConversaoNoWillMigrate() throws {
        // Store que ficou V4 com os centavos zerados porque o `didMigrate` do estágio V3 → V4 falhou.
        try criarStoreV4(valores: [19.9, 0.07], centavosJaConvertidos: false)

        let contexto = ModelContext(try CashUpPersistence.makeContainer(url: storeURL))
        let transacoes = try contexto.fetch(FetchDescriptor<ExpenseModel>())

        XCTAssertEqual(transacoes.first { $0.expenseDescription == "19.9" }?.amountInCents, 1990)
        XCTAssertEqual(transacoes.first { $0.expenseDescription == "0.07" }?.amountInCents, 7)
        XCTAssertEqual(try contexto.fetch(FetchDescriptor<SubcategoriaPlanejadaModel>()).first?.valorPlanejadoCentavos, 1990)
    }

    func testFalhaNoDidMigrateDaV5NaoDeixaTransacoesSemContaNemComTipoErrado() throws {
        try criarStoreV4(valores: [10.5], centavosJaConvertidos: true, incluirReceita: true)

        XCTAssertThrowsError(
            try ModelContainer(
                for: CashUpPersistence.schema,
                migrationPlan: PlanoV5ComFalhaNoDidMigrate.self,
                configurations: ModelConfiguration(schema: CashUpPersistence.schema, url: storeURL)
            )
        )

        // O SwiftData já aplicou a mudança estrutural: o store é V5, mas sem Carteira e com o tipo no valor padrão (despesa).
        do {
            let schema = CashUpPersistence.schema
            let container = try ModelContainer(for: schema, configurations: ModelConfiguration(schema: schema, url: storeURL))
            let contexto = ModelContext(container)
            XCTAssertEqual(try contexto.fetchCount(FetchDescriptor<ContaModel>()), 0)
            let transacoes = try contexto.fetch(FetchDescriptor<ExpenseModel>())
            XCTAssertEqual(transacoes.count, 2)
            XCTAssertTrue(transacoes.allSatisfy { $0.conta == nil && $0.tipo == .despesa })
        }

        // A abertura do app repara: todas na Carteira, e a receita volta a ser receita.
        let contexto = ModelContext(try CashUpPersistence.makeContainer(url: storeURL))
        XCTAssertEqual(try contexto.fetch(FetchDescriptor<ContaModel>()).map(\.id), [SeedIDs.idContaCarteira])
        let transacoes = try contexto.fetch(FetchDescriptor<ExpenseModel>())
        XCTAssertTrue(transacoes.allSatisfy { $0.conta?.id == SeedIDs.idContaCarteira })
        XCTAssertEqual(transacoes.first { $0.expenseDescription == "Receita" }?.tipo, .receita)
        XCTAssertEqual(transacoes.first { $0.expenseDescription == "10.5" }?.tipo, .despesa)
        XCTAssertEqual(transacoes.reduce(0) { $0 + $1.amountInCents }, 1050 + 250_000)
    }

    func testFalhaNoWillMigrateDaV5MantemOStoreNaV4EAProximaAberturaMigra() throws {
        try criarStoreV4(valores: [19.9], centavosJaConvertidos: false)

        XCTAssertThrowsError(
            try ModelContainer(
                for: CashUpPersistence.schema,
                migrationPlan: PlanoV5ComFalhaNoWillMigrate.self,
                configurations: ModelConfiguration(schema: CashUpPersistence.schema, url: storeURL)
            )
        )

        let contexto = ModelContext(try CashUpPersistence.makeContainer(url: storeURL))
        let transacao = try XCTUnwrap(try contexto.fetch(FetchDescriptor<ExpenseModel>()).first)
        XCTAssertEqual(transacao.amountInCents, 1990)
        XCTAssertEqual(transacao.conta?.id, SeedIDs.idContaCarteira)
        XCTAssertEqual(try contexto.fetchCount(FetchDescriptor<ContaModel>()), 1)
    }

    func testVinculoDeContaEhIdempotenteEPreservaTransferencia() throws {
        try criarStoreV1()
        let container = try CashUpPersistence.makeContainer(url: storeURL)
        let contexto = ModelContext(container)

        XCTAssertEqual(try CashUpMigrationPlan.vincularTransacoesPendentesAContaPadrao(em: contexto), 0)

        let transferencia = ExpenseModel(amountInCents: 500, date: marco, expenseDescription: "Transf", tipo: .transferencia)
        contexto.insert(transferencia)
        try contexto.save()

        XCTAssertEqual(try CashUpMigrationPlan.vincularTransacoesPendentesAContaPadrao(em: contexto), 1)
        XCTAssertEqual(try CashUpMigrationPlan.vincularTransacoesPendentesAContaPadrao(em: contexto), 0)
        XCTAssertEqual(transferencia.tipo, .transferencia)
        XCTAssertEqual(transferencia.conta?.id, SeedIDs.idContaCarteira)
        XCTAssertEqual(try contexto.fetchCount(FetchDescriptor<ContaModel>()), 1, "A Carteira não duplica")
    }

    /// Valores como o app sempre gravou: duas casas decimais.
    private let valoresDeDuasCasas: [Double] = [0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.2, 0.29, 4.35, 19.9, 0.07, 8.2, 1234567.89, 1234.56, 0.3]

    private let valoresComRuidoDeDouble: [Double] = [0.1, 0.2, 0.29, 4.35, 19.899999, 1.005, 2.675, 1234567.89, 0.07, 8.2, -3.2]

    private enum ErroInjetado: Error { case falhou }

    /// Plano de teste cujo estágio V3 → V4 falha depois da migração estrutural, como um `didMigrate` com erro de conversão.
    private enum PlanoComFalhaNoDidMigrate: SchemaMigrationPlan {
        static var schemas: [any VersionedSchema.Type] { [SchemaV3.self, SchemaV4.self] }
        static var stages: [MigrationStage] {
            [MigrationStage.custom(
                fromVersion: SchemaV3.self,
                toVersion: SchemaV4.self,
                willMigrate: nil,
                didMigrate: { _ in throw ErroInjetado.falhou }
            )]
        }
    }

    /// Mesmo plano, sem a falha: reabre o store já em V4 sem executar nenhum reparo.
    private enum PlanoSemFalhaNoDidMigrate: SchemaMigrationPlan {
        static var schemas: [any VersionedSchema.Type] { [SchemaV3.self, SchemaV4.self] }
        static var stages: [MigrationStage] {
            [MigrationStage.custom(fromVersion: SchemaV3.self, toVersion: SchemaV4.self, willMigrate: nil, didMigrate: nil)]
        }
    }

    /// Plano de teste cujo estágio V4 → V5 falha no `didMigrate`, depois da mudança estrutural.
    private enum PlanoV5ComFalhaNoDidMigrate: SchemaMigrationPlan {
        static var schemas: [any VersionedSchema.Type] { [SchemaV4.self, SchemaV5.self] }
        static var stages: [MigrationStage] {
            [MigrationStage.custom(
                fromVersion: SchemaV4.self,
                toVersion: SchemaV5.self,
                willMigrate: nil,
                didMigrate: { _ in throw ErroInjetado.falhou }
            )]
        }
    }

    /// Plano de teste cujo estágio V4 → V5 falha no `willMigrate`, antes de qualquer mudança estrutural.
    private enum PlanoV5ComFalhaNoWillMigrate: SchemaMigrationPlan {
        static var schemas: [any VersionedSchema.Type] { [SchemaV4.self, SchemaV5.self] }
        static var stages: [MigrationStage] {
            [MigrationStage.custom(
                fromVersion: SchemaV4.self,
                toVersion: SchemaV5.self,
                willMigrate: { _ in throw ErroInjetado.falhou },
                didMigrate: nil
            )]
        }
    }

    /// Cria um store na V4. Com `centavosJaConvertidos: false`, simula o store que ficou V4 com os centavos zerados
    /// e o `Double` legado preenchido (falha no `didMigrate` do estágio V3 → V4).
    private func criarStoreV4(valores: [Double], centavosJaConvertidos: Bool, comPlanejamento: Bool = true, incluirReceita: Bool = false) throws {
        let schema = Schema(versionedSchema: SchemaV4.self)
        let container = try ModelContainer(for: schema, configurations: ModelConfiguration(schema: schema, url: storeURL))
        let contexto = ModelContext(container)

        let categoria = SchemaV4.CategoriaModel(id: idCategoria, nome: "Transporte", icon: "car", red: 0.75, green: 0.35, blue: 0.98)
        let subcategoria = SchemaV4.SubcategoriaModel(id: idSubcategoria, nome: "Ônibus", icon: "bus", categoria: categoria)
        contexto.insert(categoria)
        contexto.insert(subcategoria)

        for valor in valores {
            contexto.insert(SchemaV4.ExpenseModel(
                amountInCents: centavosJaConvertidos ? Centavos.de(reais: valor) : 0,
                amount: centavosJaConvertidos ? 0 : valor,
                date: marco,
                expenseDescription: "\(valor)",
                categoria: categoria,
                subcategoria: subcategoria
            ))
        }
        if incluirReceita {
            contexto.insert(SchemaV4.ExpenseModel(amountInCents: 250_000, date: marco, expenseDescription: "Receita", isIncome: true))
        }

        if comPlanejamento {
            let planejada = SchemaV4.CategoriaPlanejadaModel(id: idPlanejada, mesAno: marco, categoriaOriginal: categoria)
            contexto.insert(planejada)
            contexto.insert(SchemaV4.SubcategoriaPlanejadaModel(
                valorPlanejadoCentavos: centavosJaConvertidos ? 1990 : 0,
                valorPlanejado: centavosJaConvertidos ? 0 : 19.899999,
                subcategoriaOriginal: subcategoria,
                categoriaPlanejada: planejada
            ))
        }

        try contexto.save()
    }

    /// Cria um store na V3 (reais em `Double`), a versão publicada antes da E0.3.
    private func criarStoreV3(valores: [Double]) throws {
        let schema = Schema(versionedSchema: SchemaV3.self)
        let container = try ModelContainer(for: schema, configurations: ModelConfiguration(schema: schema, url: storeURL))
        let contexto = ModelContext(container)

        let categoria = SchemaV3.CategoriaModel(id: idCategoria, nome: "Transporte", icon: "car", red: 0.75, green: 0.35, blue: 0.98)
        let subcategoria = SchemaV3.SubcategoriaModel(id: idSubcategoria, nome: "Ônibus", icon: "bus", categoria: categoria)
        contexto.insert(categoria)
        contexto.insert(subcategoria)

        for valor in valores {
            contexto.insert(SchemaV3.ExpenseModel(
                amount: valor,
                date: marco,
                expenseDescription: "\(valor)",
                categoria: categoria,
                subcategoria: subcategoria
            ))
        }

        let planejada = SchemaV3.CategoriaPlanejadaModel(id: idPlanejada, mesAno: marco, categoriaOriginal: categoria)
        contexto.insert(planejada)
        contexto.insert(SchemaV3.SubcategoriaPlanejadaModel(valorPlanejado: 19.899999, subcategoriaOriginal: subcategoria, categoriaPlanejada: planejada))

        try contexto.save()
    }

    /// Cria o store como o `main` (App Store 1.5) criava: schema sem versão, só com a lista de modelos.
    private func criarStoreV1() throws {
        let schema = Schema(SchemaV1.models)
        let container = try ModelContainer(for: schema, configurations: ModelConfiguration(schema: schema, url: storeURL))
        let contexto = ModelContext(container)

        let categoria = SchemaV1.CategoriaModel(id: idCategoria, nome: "Transporte", icon: "car", red: 0.75, green: 0.35, blue: 0.98)
        let subcategoria = SchemaV1.SubcategoriaModel(id: idSubcategoria, nome: "Ônibus", icon: "bus", categoria: categoria, usageCount: 3)
        contexto.insert(categoria)
        contexto.insert(subcategoria)

        contexto.insert(SchemaV1.ExpenseModel(
            id: idRecorrente,
            amount: 49.9,
            date: marco,
            expenseDescription: "Passe",
            repetition: RepetitionData(repeatOption: .mensalmente, endDate: nil, excludedDates: [excluida]),
            categoria: categoria,
            subcategoria: subcategoria
        ))
        contexto.insert(SchemaV1.ExpenseModel(
            id: idReceita,
            amount: 1800,
            date: marco,
            expenseDescription: "Bolsa",
            isIncome: true,
            categoria: categoria,
            subcategoria: subcategoria
        ))

        let planejada = SchemaV1.CategoriaPlanejadaModel(id: idPlanejada, mesAno: marco, categoriaOriginal: categoria)
        contexto.insert(planejada)
        contexto.insert(SchemaV1.SubcategoriaPlanejadaModel(valorPlanejado: 300, subcategoriaOriginal: subcategoria, categoriaPlanejada: planejada))

        try contexto.save()
    }
}
