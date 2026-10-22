import XCTest
@testable import CashUp

final class RecommendedPlanningServiceTests: XCTestCase {
    private var sut: RecommendedPlanningService!

    override func setUp() {
        super.setUp()
        sut = RecommendedPlanningService()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testRendaZeradaOuNegativaRetornaVazio() {
        let cat = CategoriaModel(nome: "Alimentação", icon: "cart", red: 1.0, green: 0.0, blue: 0.0)
        XCTAssertTrue(sut.gerarPlanejamentoRecomendado(rendaMensal: 0, categoriasDisponiveis: [cat]).isEmpty)
        XCTAssertTrue(sut.gerarPlanejamentoRecomendado(rendaMensal: -100, categoriasDisponiveis: [cat]).isEmpty)
    }

    func testIgnoraCategoriaRenda() {
        let catRenda = CategoriaModel(id: SeedIDs.idRenda, nome: "Renda", icon: "banknote", red: 0.0, green: 1.0, blue: 0.0)
        let catComida = CategoriaModel(nome: "Comidas e Bebidas", icon: "fork.knife", red: 1.0, green: 0.5, blue: 0.0)

        let resultado = sut.gerarPlanejamentoRecomendado(rendaMensal: 3000, categoriasDisponiveis: [catRenda, catComida])
        XCTAssertFalse(resultado.contains(where: { $0.categoria.id == catRenda.id }))
        XCTAssertTrue(resultado.contains(where: { $0.categoria.id == catComida.id }))
    }

    func testDistribuicao503020ComCategoriasBase() {
        let catHabitacao = CategoriaModel(nome: "Habitação", icon: "house", red: 0.0, green: 0.0, blue: 1.0)
        let subAluguel = SubcategoriaModel(nome: "Aluguel", icon: "house.fill")
        catHabitacao.subcategorias = [subAluguel]

        let catComida = CategoriaModel(nome: "Comidas e Bebidas", icon: "fork.knife", red: 1.0, green: 0.5, blue: 0.0)
        let subMercado = SubcategoriaModel(nome: "Mantimentos", icon: "cart.fill")
        catComida.subcategorias = [subMercado]

        let catTransporte = CategoriaModel(nome: "Transporte", icon: "car", red: 0.5, green: 0.5, blue: 0.5)
        let subCombustivel = SubcategoriaModel(nome: "Combustível", icon: "fuelpump.fill")
        catTransporte.subcategorias = [subCombustivel]

        let catLazer = CategoriaModel(nome: "Entretenimento", icon: "tv", red: 0.8, green: 0.2, blue: 0.8)
        let catEstilo = CategoriaModel(nome: "Estilo de Vida", icon: "tshirt", red: 0.9, green: 0.4, blue: 0.1)
        let catDiversos = CategoriaModel(nome: "Diversos", icon: "ellipsis.circle", red: 0.3, green: 0.3, blue: 0.3)

        let categorias = [catHabitacao, catComida, catTransporte, catLazer, catEstilo, catDiversos]
        let renda: Double = 4000.0

        let itens = sut.gerarPlanejamentoRecomendado(rendaMensal: renda, categoriasDisponiveis: categorias)

        let itemHabitacao = itens.first(where: { $0.categoria.id == catHabitacao.id })
        XCTAssertNotNil(itemHabitacao)
        XCTAssertEqual(itemHabitacao?.valorSugerido, 1000.0)
        XCTAssertEqual(itemHabitacao?.subcategoria?.id, subAluguel.id)

        let itemComida = itens.first(where: { $0.categoria.id == catComida.id })
        XCTAssertNotNil(itemComida)
        XCTAssertEqual(itemComida?.valorSugerido, 600.0)
        XCTAssertEqual(itemComida?.subcategoria?.id, subMercado.id)

        let itemTransporte = itens.first(where: { $0.categoria.id == catTransporte.id })
        XCTAssertNotNil(itemTransporte)
        XCTAssertEqual(itemTransporte?.valorSugerido, 400.0)

        let totalNecessidades = itens.filter { $0.grupo == .necessidades }.reduce(0.0) { $0 + $1.valorSugerido }
        let totalDesejos = itens.filter { $0.grupo == .desejos }.reduce(0.0) { $0 + $1.valorSugerido }
        let totalPoupanca = itens.filter { $0.grupo == .futuroPoupanca }.reduce(0.0) { $0 + $1.valorSugerido }

        XCTAssertEqual(totalNecessidades, 2000.0, accuracy: 10.0)
        XCTAssertEqual(totalDesejos, 1200.0, accuracy: 10.0)
        XCTAssertEqual(totalPoupanca, 800.0, accuracy: 10.0)
    }
}
