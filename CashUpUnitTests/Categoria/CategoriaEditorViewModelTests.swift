import XCTest
import SwiftUI
@testable import CashUp

@MainActor
final class CategoriaEditorViewModelTests: XCTestCase {
    private var repository: InMemoryCategoriaRepository!

    override func setUp() {
        super.setUp()
        let catRenda = CategoriaModel(
            id: SeedIDs.idRenda,
            nome: "Renda",
            icon: "dollarsign",
            red: 0.14,
            green: 0.70,
            blue: 0.28
        )
        let subRenda = SubcategoriaModel(
            id: SeedIDs.idSubRendaGeral,
            nome: "Renda",
            icon: "arrow.down.to.line.circle.fill",
            categoria: catRenda
        )
        catRenda.subcategorias = [subRenda]

        let catLazer = CategoriaModel(
            id: UUID(),
            nome: "Lazer",
            icon: "gamecontroller",
            red: 1.0,
            green: 0.39,
            blue: 0.51
        )
        let subCinema = SubcategoriaModel(id: UUID(), nome: "Cinema", icon: "movieclapper.fill", categoria: catLazer)
        let subDiversos = SubcategoriaModel(id: UUID(), nome: "Diversos", icon: "archivebox.fill", categoria: catLazer)
        catLazer.subcategorias = [subCinema, subDiversos]

        repository = InMemoryCategoriaRepository(categorias: [catRenda, catLazer])
    }

    override func tearDown() {
        repository = nil
        super.tearDown()
    }

    private func makeSUT() -> CategoriaEditorViewModel {
        CategoriaEditorViewModel(repository: repository)
    }

    func testCarregarPreencheCategoriasDoRepositorio() {
        let sut = makeSUT()
        XCTAssertEqual(sut.categorias.count, 2)
    }

    func testCriarCategoriaValidaComSucesso() throws {
        let sut = makeSUT()
        let cor = CategoriaPalette.coresDisponiveis.first { $0.id == "azul_eletrico" }!

        let nova = try sut.criarCategoria(nome: "Tecnologia", cor: cor, icone: "laptopcomputer")

        XCTAssertEqual(nova.nome, "Tecnologia")
        XCTAssertEqual(nova.icon, "laptopcomputer")
        XCTAssertEqual(nova.subcategorias.count, 1)
        XCTAssertEqual(nova.subcategorias.first?.nome, "Diversos")
        XCTAssertEqual(sut.categorias.count, 3)
        XCTAssertEqual(repository.saveCallCount, 1)
    }

    func testCriarCategoriaComNomeInvalidoFalha() {
        let sut = makeSUT()
        let cor = CategoriaPalette.coresDisponiveis[0]

        XCTAssertThrowsError(try sut.criarCategoria(nome: "A", cor: cor, icone: "star")) { error in
            XCTAssertEqual(error as? CashUpDomainError, .nomeInvalido)
        }

        XCTAssertThrowsError(try sut.criarCategoria(nome: String(repeating: "C", count: 25), cor: cor, icone: "star")) { error in
            XCTAssertEqual(error as? CashUpDomainError, .nomeInvalido)
        }
    }

    func testCriarCategoriaComNomeDuplicadoFalha() {
        let sut = makeSUT()
        let cor = CategoriaPalette.coresDisponiveis[0]

        XCTAssertThrowsError(try sut.criarCategoria(nome: "Lazer", cor: cor, icone: "star")) { error in
            XCTAssertEqual(error as? CashUpDomainError, .nomeDuplicado("Lazer"))
        }

        XCTAssertThrowsError(try sut.criarCategoria(nome: "lazer", cor: cor, icone: "star")) { error in
            XCTAssertEqual(error as? CashUpDomainError, .nomeDuplicado("lazer"))
        }
    }

    func testCriarCategoriaComCorJaEmUsoFalha() {
        let sut = makeSUT()
        let corEmUso = CategoriaCor(id: "rosa", nome: "Rosa", red: 1.0, green: 0.39, blue: 0.51)

        XCTAssertThrowsError(try sut.criarCategoria(nome: "Festas", cor: corEmUso, icone: "party.popper.fill")) { error in
            XCTAssertEqual(error as? CashUpDomainError, .corEmUso)
        }
    }

    func testEditarCategoriaValidaComSucesso() throws {
        let sut = makeSUT()
        let customCat = CategoriaModel(
            id: UUID(),
            nome: "Custom",
            icon: "star",
            red: 0.85,
            green: 0.10,
            blue: 0.65
        )
        repository.insert(customCat)
        sut.carregar()

        let novaCor = CategoriaPalette.coresDisponiveis.first { $0.id == "violeta" }!

        try sut.editarCategoria(customCat, novoNome: "Custom Novo", novaCor: novaCor, novoIcone: "tv.fill")

        XCTAssertEqual(customCat.nome, "Custom Novo")
        XCTAssertEqual(customCat.icon, "tv.fill")
        XCTAssertEqual(customCat.redComponent, novaCor.red)
        XCTAssertEqual(repository.saveCallCount, 1)
    }

    func testEditarCorDeCategoriaBaseFalha() {
        let sut = makeSUT()
        let catBase = CategoriaModel(
            id: SeedIDs.idEntretenimento,
            nome: "Entretenimento",
            icon: "gamecontroller",
            red: 1.0,
            green: 0.39,
            blue: 0.51
        )
        repository.insert(catBase)
        sut.carregar()

        let novaCor = CategoriaPalette.coresDisponiveis.first { $0.id == "ambar" }!

        XCTAssertThrowsError(try sut.editarCategoria(catBase, novoNome: "Entretenimento", novaCor: novaCor, novoIcone: "gamecontroller")) { error in
            XCTAssertEqual(error as? CashUpDomainError, .corCategoriaBaseProtegida)
        }
    }

    func testEditarNomeEIconeDeCategoriaBaseComSucesso() throws {
        let sut = makeSUT()
        let catBase = CategoriaModel(
            id: SeedIDs.idEntretenimento,
            nome: "Entretenimento",
            icon: "gamecontroller",
            red: 1.0,
            green: 0.39,
            blue: 0.51
        )
        repository.insert(catBase)
        sut.carregar()

        let mesmaCor = CategoriaCor(id: "base", nome: "Base", red: 1.0, green: 0.39, blue: 0.51)

        try sut.editarCategoria(catBase, novoNome: "Jogos & Filmes", novaCor: mesmaCor, novoIcone: "film.fill")

        XCTAssertEqual(catBase.nome, "Jogos & Filmes")
        XCTAssertEqual(catBase.icon, "film.fill")
        XCTAssertEqual(catBase.redComponent, 1.0)
    }

    func testEditarCategoriaRendaFalha() {
        let sut = makeSUT()
        let renda = sut.categorias.first { $0.id == SeedIDs.idRenda }!
        let novaCor = CategoriaPalette.coresDisponiveis[0]

        XCTAssertThrowsError(try sut.editarCategoria(renda, novoNome: "Salários", novaCor: novaCor, novoIcone: "banknote")) { error in
            XCTAssertEqual(error as? CashUpDomainError, .categoriaProtegida)
        }
    }

    func testEditarCategoriaComNomeDuplicadoFalha() throws {
        let sut = makeSUT()
        let cor = CategoriaPalette.coresDisponiveis.first { $0.id == "ambar" }!
        let nova = try sut.criarCategoria(nome: "Viagens", cor: cor, icone: "airplane")

        XCTAssertThrowsError(try sut.editarCategoria(nova, novoNome: "Lazer", novaCor: cor, novoIcone: "airplane")) { error in
            XCTAssertEqual(error as? CashUpDomainError, .nomeDuplicado("Lazer"))
        }
    }

    func testApagarCategoriaSemTransacoesComSucesso() throws {
        let sut = makeSUT()
        let lazer = sut.categorias.first { $0.nome == "Lazer" }!

        try sut.apagarCategoria(lazer)

        XCTAssertEqual(sut.categorias.count, 1)
        XCTAssertFalse(sut.categorias.contains { $0.nome == "Lazer" })
        XCTAssertEqual(repository.saveCallCount, 1)
    }

    func testApagarCategoriaRendaFalha() {
        let sut = makeSUT()
        let renda = sut.categorias.first { $0.id == SeedIDs.idRenda }!

        XCTAssertThrowsError(try sut.apagarCategoria(renda)) { error in
            XCTAssertEqual(error as? CashUpDomainError, .categoriaProtegida)
        }
    }

    func testApagarCategoriaComTransacoesFalha() {
        let sut = makeSUT()
        let lazer = sut.categorias.first { $0.nome == "Lazer" }!
        let transacao = ExpenseModel(amount: 50.0, date: Date(), expenseDescription: "Cinema", categoria: lazer)
        lazer.transacoes = [transacao]

        XCTAssertThrowsError(try sut.apagarCategoria(lazer)) { error in
            XCTAssertEqual(error as? CashUpDomainError, .categoriaEmUso(quantidadeTransacoes: 1))
        }
    }

    func testCriarSubcategoriaComSucesso() throws {
        let sut = makeSUT()
        let lazer = sut.categorias.first { $0.nome == "Lazer" }!

        let novaSub = try sut.criarSubcategoria(em: lazer, nome: "Jogos", icone: "gamecontroller.fill")

        XCTAssertEqual(novaSub.nome, "Jogos")
        XCTAssertTrue(lazer.subcategorias.contains { $0.nome == "Jogos" })
        XCTAssertEqual(repository.saveCallCount, 1)
    }

    func testCriarSubcategoriaComNomeDuplicadoFalha() {
        let sut = makeSUT()
        let lazer = sut.categorias.first { $0.nome == "Lazer" }!

        XCTAssertThrowsError(try sut.criarSubcategoria(em: lazer, nome: "Cinema", icone: "film")) { error in
            XCTAssertEqual(error as? CashUpDomainError, .nomeDuplicado("Cinema"))
        }
    }

    func testEditarSubcategoriaComSucesso() throws {
        let sut = makeSUT()
        let lazer = sut.categorias.first { $0.nome == "Lazer" }!
        let cinema = lazer.subcategorias.first { $0.nome == "Cinema" }!

        try sut.editarSubcategoria(cinema, novoNome: "Filmes & Séries", novoIcone: "film.fill")

        XCTAssertEqual(cinema.nome, "Filmes & Séries")
        XCTAssertEqual(cinema.icon, "film.fill")
        XCTAssertEqual(repository.saveCallCount, 1)
    }

    func testApagarSubcategoriaComTransacoesRemanejaParaDiversos() throws {
        let sut = makeSUT()
        let lazer = sut.categorias.first { $0.nome == "Lazer" }!
        let cinema = lazer.subcategorias.first { $0.nome == "Cinema" }!
        let diversos = lazer.subcategorias.first { $0.nome == "Diversos" }!

        let transacao = ExpenseModel(amount: 30.0, date: Date(), expenseDescription: "Ingresso", categoria: lazer, subcategoria: cinema)
        cinema.transacoes = [transacao]

        try sut.apagarSubcategoria(cinema)

        XCTAssertFalse(lazer.subcategorias.contains { $0.nome == "Cinema" })
        XCTAssertEqual(transacao.subcategoria?.id, diversos.id)
        XCTAssertEqual(repository.saveCallCount, 1)
    }

    func testApagarUltimaSubcategoriaDeRendaFalha() {
        let sut = makeSUT()
        let renda = sut.categorias.first { $0.id == SeedIDs.idRenda }!
        let unicaSub = renda.subcategorias.first!

        XCTAssertThrowsError(try sut.apagarSubcategoria(unicaSub)) { error in
            XCTAssertEqual(error as? CashUpDomainError, .subcategoriaProtegida)
        }
    }

    func testApagarSubcategoriaComTransacoesSemDestinoFalha() {
        let sut = makeSUT()
        let cat = CategoriaModel(id: UUID(), nome: "Avulsa", icon: "tag", red: 0.1, green: 0.2, blue: 0.3)
        let sub = SubcategoriaModel(id: UUID(), nome: "Unica", icon: "tag", categoria: cat)
        cat.subcategorias = [sub]
        let transacao = ExpenseModel(amount: 10.0, date: Date(), expenseDescription: "Teste", categoria: cat, subcategoria: sub)
        sub.transacoes = [transacao]

        XCTAssertThrowsError(try sut.apagarSubcategoria(sub)) { error in
            XCTAssertEqual(error as? CashUpDomainError, .subcategoriaEmUso(quantidadeTransacoes: 1))
        }
    }
}
