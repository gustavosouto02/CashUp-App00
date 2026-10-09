import SwiftData
import XCTest
@testable import CashUp

@MainActor
final class SwiftDataExpenseRepositoryTests: XCTestCase {
    private var container: ModelContainer!
    private var context: ModelContext!
    private var sut: SwiftDataExpenseRepository!

    override func setUpWithError() throws {
        let schema = Schema([
            ExpenseModel.self,
            CategoriaModel.self,
            SubcategoriaModel.self,
            CategoriaPlanejadaModel.self,
            SubcategoriaPlanejadaModel.self,
        ])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: config)
        context = ModelContext(container)
        sut = SwiftDataExpenseRepository(context: context)
    }

    override func tearDownWithError() throws {
        container = nil
        context = nil
        sut = nil
    }

    func testInserirEBuscarTodasTransacoes() throws {
        let expense = ExpenseModel(
            amount: 50.0,
            date: Date.make(year: 2026, month: 3, day: 10),
            expenseDescription: "Mercado"
        )
        sut.insert(expense)
        try sut.save()

        let todas = try sut.fetchAll()
        XCTAssertEqual(todas.count, 1)
        XCTAssertEqual(todas.first?.expenseDescription, "Mercado")
    }

    func testBuscarPorID() throws {
        let id = UUID()
        let expense = ExpenseModel(
            id: id,
            amount: 100.0,
            date: Date.make(year: 2026, month: 3, day: 10),
            expenseDescription: "Aluguel"
        )
        sut.insert(expense)
        try sut.save()

        let encontrada = try sut.fetch(id: id)
        XCTAssertNotNil(encontrada)
        XCTAssertEqual(encontrada?.amount, 100.0)

        let naoEncontrada = try sut.fetch(id: UUID())
        XCTAssertNil(naoEncontrada)
    }

    func testDeletarTransacao() throws {
        let expense = ExpenseModel(
            amount: 25.0,
            date: Date.make(year: 2026, month: 3, day: 12),
            expenseDescription: "Lanche"
        )
        sut.insert(expense)
        try sut.save()

        XCTAssertEqual(try sut.fetchAll().count, 1)

        sut.delete(expense)
        try sut.save()

        XCTAssertEqual(try sut.fetchAll().count, 0)
    }
}
