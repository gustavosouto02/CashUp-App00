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
        XCTAssertEqual(transacoes.reduce(0) { $0 + $1.amount }, 1849.9, accuracy: 0.0001)
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

        XCTAssertEqual(Set(transacoes.map(\.instanciaID)).count, transacoes.count)
        XCTAssertTrue(transacoes.allSatisfy { $0.criadoEm == .distantPast })
        XCTAssertEqual(try contexto.fetchCount(FetchDescriptor<SeedRemocaoModel>()), 0)
    }

    func testMigracaoPreservaPlanejamento() throws {
        try criarStoreV1()

        let contexto = ModelContext(try CashUpPersistence.makeContainer(url: storeURL))
        let planejada = try XCTUnwrap(try contexto.fetch(FetchDescriptor<CategoriaPlanejadaModel>()).first)

        XCTAssertEqual(planejada.id, idPlanejada)
        XCTAssertEqual(planejada.mesAno, marco.startOfMonth())
        XCTAssertEqual(planejada.categoriaOriginal?.id, idCategoria)
        XCTAssertEqual(planejada.valorTotalPlanejado, 300, accuracy: 0.0001)
        XCTAssertEqual(planejada.subcategoriasPlanejadas?.first?.subcategoriaOriginal?.id, idSubcategoria)
    }

    func testStoreAtualReabreSemPerderDados() throws {
        try criarStoreV1()

        do {
            let contexto = ModelContext(try CashUpPersistence.makeContainer(url: storeURL))
            contexto.insert(ExpenseModel(amount: 10, date: marco, expenseDescription: "Café"))
            try contexto.save()
        }

        let contexto = ModelContext(try CashUpPersistence.makeContainer(url: storeURL))
        XCTAssertEqual(try contexto.fetchCount(FetchDescriptor<ExpenseModel>()), 3)
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
