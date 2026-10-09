import XCTest
import SwiftData
@testable import CashUp

@MainActor
final class ExpenseCalculationByMonthTests: XCTestCase {
    private var container: ModelContainer!
    private var context: ModelContext!
    private var viewModel: ExpensesViewModel!
    private var categoria: CategoriaModel!
    private var mercado: SubcategoriaModel!
    private var restaurante: SubcategoriaModel!

    private let marco = Date.make(year: 2026, month: 3, day: 10)
    private let abril = Date.make(year: 2026, month: 4, day: 10)

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
        categoria = CategoriaModel(nome: "Comidas", icon: "fork.knife", red: 0, green: 0.5, blue: 0.5)
        mercado = SubcategoriaModel(nome: "Mercado", icon: "cart", categoria: categoria)
        restaurante = SubcategoriaModel(nome: "Restaurante", icon: "fork.knife.circle", categoria: categoria)
        context.insert(categoria)
        context.insert(mercado)
        context.insert(restaurante)

        context.insert(ExpenseModel(amount: 100, date: marco, categoria: categoria, subcategoria: mercado))
        context.insert(ExpenseModel(amount: 40, date: marco, categoria: categoria, subcategoria: restaurante))
        context.insert(ExpenseModel(amount: 500, date: marco, isIncome: true, categoria: categoria, subcategoria: mercado))
        context.insert(ExpenseModel(amount: 250, date: abril, categoria: categoria, subcategoria: mercado))
        try context.save()

        viewModel = ExpensesViewModel(modelContext: context)
        viewModel.currentMonth = abril
    }

    override func tearDownWithError() throws {
        viewModel = nil
        context = nil
        container = nil
        try super.tearDownWithError()
    }

    private func planejamento(mes: Date, subcategorias: [SubcategoriaModel]) -> CategoriaPlanejadaModel {
        let plano = CategoriaPlanejadaModel(mesAno: mes, categoriaOriginal: categoria)
        plano.subcategoriasPlanejadas = subcategorias.map {
            SubcategoriaPlanejadaModel(valorPlanejado: 300, subcategoriaOriginal: $0, categoriaPlanejada: plano)
        }
        return plano
    }

    func testTotalGastoParaCategoriaHonraOMesPedidoENaoOMesAtual() {
        let plano = planejamento(mes: marco, subcategorias: [mercado])

        XCTAssertEqual(viewModel.calcularTotalGastoParaCategoria(plano, paraMes: marco), 140)
        XCTAssertEqual(viewModel.calcularTotalGastoParaCategoria(plano, paraMes: abril), 250)
    }

    func testTotalGastoParaSubcategoriaHonraOMesPedido() {
        let plano = planejamento(mes: marco, subcategorias: [mercado, restaurante])
        let subMercado = plano.subcategoriasPlanejadas!.first { $0.subcategoriaOriginal?.id == mercado.id }!

        XCTAssertEqual(viewModel.calcularTotalGastoParaSubcategoria(subMercado, paraMes: marco), 100)
        XCTAssertEqual(viewModel.calcularTotalGastoParaSubcategoria(subMercado, paraMes: abril), 250)
    }

    func testTotalGastoEmCategoriasPlanejadasIgnoraReceitasESubcategoriasNaoPlanejadas() {
        let plano = planejamento(mes: marco, subcategorias: [mercado])

        XCTAssertEqual(viewModel.calcularTotalGastoEmCategoriasPlanejadas(paraMes: marco, categoriasPlanejadas: [plano]), 100)
    }

    func testTotaisPorSubcategoriaAgrupaSomenteDespesas() {
        let totais = viewModel.totaisPorSubcategoria(in: marco)

        XCTAssertEqual(totais.count, 2)
        XCTAssertEqual(totais[mercado.id], 100)
        XCTAssertEqual(totais[restaurante.id], 40)
    }

    func testTotaisDeReceitaEDespesaPorMes() {
        XCTAssertEqual(viewModel.totalExpense(in: marco), 140)
        XCTAssertEqual(viewModel.totalIncome(in: marco), 500)
        XCTAssertEqual(viewModel.totalExpense(in: abril), 250)
        XCTAssertEqual(viewModel.totalIncome(in: abril), 0)
    }

    func testTransacoesDoDiaFiltraPorDiaETipo() {
        XCTAssertEqual(viewModel.transactions(on: marco, isIncome: nil).count, 3)
        XCTAssertEqual(viewModel.transactions(on: marco, isIncome: false).count, 2)
        XCTAssertEqual(viewModel.transactions(on: Date.make(year: 2026, month: 3, day: 11), isIncome: nil).count, 0)
    }
}
