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
        XCTAssertTrue(sut.gerarPlanejamentoRecomendado(rendaMensalCentavos: 0, categoriasDisponiveis: [cat]).isEmpty)
        XCTAssertTrue(sut.gerarPlanejamentoRecomendado(rendaMensalCentavos: -10_000, categoriasDisponiveis: [cat]).isEmpty)
    }

    func testIgnoraCategoriaRenda() {
        let catRenda = CategoriaModel(id: SeedIDs.idRenda, nome: "Renda", icon: "banknote", red: 0.0, green: 1.0, blue: 0.0)
        let catComida = CategoriaModel(nome: "Comidas e Bebidas", icon: "fork.knife", red: 1.0, green: 0.5, blue: 0.0)

        let resultado = sut.gerarPlanejamentoRecomendado(rendaMensalCentavos: 300_000, categoriasDisponiveis: [catRenda, catComida])
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
        let renda: Int64 = 400_000

        let itens = sut.gerarPlanejamentoRecomendado(rendaMensalCentavos: renda, categoriasDisponiveis: categorias)

        let itemHabitacao = itens.first(where: { $0.categoria.id == catHabitacao.id })
        XCTAssertNotNil(itemHabitacao)
        XCTAssertEqual(itemHabitacao?.valorSugeridoCentavos, 100_000)
        XCTAssertEqual(itemHabitacao?.subcategoria?.id, subAluguel.id)

        let itemComida = itens.first(where: { $0.categoria.id == catComida.id })
        XCTAssertNotNil(itemComida)
        XCTAssertEqual(itemComida?.valorSugeridoCentavos, 60_000)
        XCTAssertEqual(itemComida?.subcategoria?.id, subMercado.id)

        let itemTransporte = itens.first(where: { $0.categoria.id == catTransporte.id })
        XCTAssertNotNil(itemTransporte)
        XCTAssertEqual(itemTransporte?.valorSugeridoCentavos, 40_000)

        let totalNecessidades = itens.filter { $0.grupo == .necessidades }.reduce(0) { $0 + $1.valorSugeridoCentavos }
        let totalDesejos = itens.filter { $0.grupo == .desejos }.reduce(0) { $0 + $1.valorSugeridoCentavos }
        let totalPoupanca = itens.filter { $0.grupo == .futuroPoupanca }.reduce(0) { $0 + $1.valorSugeridoCentavos }

        XCTAssertEqual(totalNecessidades, 200_000)
        XCTAssertEqual(totalDesejos, 120_000)
        XCTAssertEqual(totalPoupanca, 80_000)
        XCTAssertEqual(itens.reduce(0) { $0 + $1.valorSugeridoCentavos }, renda)
    }

    func testHabitacaoArredondaUmaVezPartindoDoValorExato() {
        // 25% de R$ 1.009,99 = R$ 252,4975: o múltiplo de R$ 5 mais próximo é R$ 250 (arredondar o centavo antes daria R$ 255).
        let catHabitacao = CategoriaModel(nome: "Habitação", icon: "house", red: 0.0, green: 0.0, blue: 1.0)
        let catSaude = CategoriaModel(nome: "Saúde", icon: "cross", red: 0.5, green: 0.0, blue: 0.0) // absorve a sobra das necessidades
        let catLazer = CategoriaModel(nome: "Entretenimento", icon: "tv", red: 0.8, green: 0.2, blue: 0.8)
        let catDiversos = CategoriaModel(nome: "Diversos", icon: "ellipsis.circle", red: 0.3, green: 0.3, blue: 0.3)
        let renda: Int64 = 100_999

        let itens = sut.gerarPlanejamentoRecomendado(rendaMensalCentavos: renda, categoriasDisponiveis: [catHabitacao, catSaude, catLazer, catDiversos])

        XCTAssertEqual(itens.first(where: { $0.categoria.id == catHabitacao.id })?.valorSugeridoCentavos, 25_000)
    }

    func testSobraDasNecessidadesArredondaUmaVezAoDividirEntreOsRestantes() {
        // Sobra de R$ 1.004,99 dividida entre 2 categorias = R$ 502,495: o múltiplo mais próximo é R$ 500 (e não R$ 505).
        let catHabitacao = CategoriaModel(nome: "Habitação", icon: "house", red: 0.0, green: 0.0, blue: 1.0)
        let catSaude = CategoriaModel(nome: "Saúde", icon: "cross", red: 0.5, green: 0.0, blue: 0.0)
        let catEducacao = CategoriaModel(nome: "Educação", icon: "book", red: 0.0, green: 0.5, blue: 0.0)
        let catLazer = CategoriaModel(nome: "Entretenimento", icon: "tv", red: 0.8, green: 0.2, blue: 0.8)
        let catDiversos = CategoriaModel(nome: "Diversos", icon: "ellipsis.circle", red: 0.3, green: 0.3, blue: 0.3)
        // 50% = 200.999 e Habitação = 100.500, então a sobra é 100.499.
        let renda: Int64 = 401_998

        let itens = sut.gerarPlanejamentoRecomendado(
            rendaMensalCentavos: renda,
            categoriasDisponiveis: [catHabitacao, catSaude, catEducacao, catLazer, catDiversos]
        )

        XCTAssertEqual(itens.first(where: { $0.categoria.id == catHabitacao.id })?.valorSugeridoCentavos, 100_500)
        XCTAssertEqual(itens.first(where: { $0.categoria.id == catSaude.id })?.valorSugeridoCentavos, 50_000)
        XCTAssertEqual(itens.first(where: { $0.categoria.id == catEducacao.id })?.valorSugeridoCentavos, 50_499)
        XCTAssertEqual(itens.filter { $0.grupo == .necessidades }.reduce(0) { $0 + $1.valorSugeridoCentavos }, 200_999)
        XCTAssertEqual(itens.reduce(0) { $0 + $1.valorSugeridoCentavos }, renda)
    }

    func testDiversosComoPoupancaSelecionaSubcategoriaReserva() throws {
        let catDiversos = CategoriaModel(nome: "Diversos", icon: "archivebox", red: 0.3, green: 0.3, blue: 0.3)
        let subCustosBancarios = SubcategoriaModel(nome: "Custos Bancários", icon: "dollarsign")
        let subReserva = SubcategoriaModel(nome: "Reserva", icon: "shield.fill")
        let subOutros = SubcategoriaModel(nome: "Diversos", icon: "tag")
        catDiversos.subcategorias = [subCustosBancarios, subReserva, subOutros]

        let catComida = CategoriaModel(nome: "Comida", icon: "fork.knife", red: 1.0, green: 0.5, blue: 0.0)
        let subMercado = SubcategoriaModel(nome: "Mercado", icon: "cart")
        catComida.subcategorias = [subMercado]

        let itens = sut.gerarPlanejamentoRecomendado(rendaMensalCentavos: 300_000, categoriasDisponiveis: [catComida, catDiversos])
        let itemPoupanca = try XCTUnwrap(itens.first(where: { $0.grupo == .futuroPoupanca }))

        XCTAssertEqual(itemPoupanca.categoria.id, catDiversos.id)
        XCTAssertEqual(itemPoupanca.subcategoria?.nome, "Reserva")
        XCTAssertEqual(itemPoupanca.valorSugeridoCentavos, 60_000)
    }
}
