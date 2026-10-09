import SwiftData
import XCTest

@testable import CashUp

@MainActor
final class CategoriaDeleteRuleTests: XCTestCase {
    private var container: ModelContainer!
    private var context: ModelContext!

    override func setUpWithError() throws {
        try super.setUpWithError()
        let schema = Schema([
            CategoriaModel.self,
            SubcategoriaModel.self,
            ExpenseModel.self,
            CategoriaPlanejadaModel.self,
            SubcategoriaPlanejadaModel.self,
        ])
        container = try ModelContainer(for: schema, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        context = ModelContext(container)
    }

    override func tearDownWithError() throws {
        context = nil
        container = nil
    }

    func testApagarCategoriaAnulaReferenciasDasTransacoes() throws {
        let categoria = CategoriaModel(nome: "Lazer", icon: "gamecontroller", red: 0.1, green: 0.2, blue: 0.3)
        let subcategoria = SubcategoriaModel(nome: "Cinema", icon: "film", categoria: categoria)
        let transacao = ExpenseModel(
            amount: 40,
            date: Date.make(year: 2026, month: 3, day: 10),
            expenseDescription: "Ingresso",
            categoria: categoria,
            subcategoria: subcategoria
        )
        context.insert(categoria)
        context.insert(subcategoria)
        context.insert(transacao)
        try context.save()

        context.delete(categoria)
        try context.save()

        let restantes = try context.fetch(FetchDescriptor<ExpenseModel>())
        XCTAssertEqual(restantes.count, 1, "A transação não pode ser apagada junto com a categoria")
        XCTAssertNil(restantes.first?.categoria)
        XCTAssertNil(restantes.first?.subcategoria, "A subcategoria some em cascata e a referência é anulada")
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<SubcategoriaModel>()), 0)
    }
}
