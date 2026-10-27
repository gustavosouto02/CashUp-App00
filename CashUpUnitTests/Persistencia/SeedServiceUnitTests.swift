import SwiftData
import XCTest

@testable import CashUp

@MainActor
final class SeedServiceUnitTests: XCTestCase {
    private var container: ModelContainer!
    private var context: ModelContext!
    private var settings: InMemoryAppSettings!
    private let ptBR = Locale(identifier: "pt_BR")

    override func setUpWithError() throws {
        try super.setUpWithError()
        container = try CashUpPersistence.makeContainer(inMemory: true)
        context = ModelContext(container)
        settings = InMemoryAppSettings()
    }

    override func tearDownWithError() throws {
        context = nil
        container = nil
        settings = nil
    }

    private func aplicarSeed(locale: Locale? = nil) throws {
        try SeedService(settings: settings).aplicar(em: context, locale: locale ?? ptBR)
    }

    private func categoria(id: UUID) throws -> CategoriaModel? {
        try context.fetch(FetchDescriptor<CategoriaModel>(predicate: #Predicate { $0.id == id })).first
    }

    func testSeedExecutadoDuasVezesNaoDuplicaDados() throws {
        try aplicarSeed()
        try aplicarSeed()

        XCTAssertEqual(try context.fetchCount(FetchDescriptor<CategoriaModel>()), 7)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<SubcategoriaModel>()), 72)
        XCTAssertEqual(settings.seedVersaoAplicada, SeedCatalogo.versao)
    }

    func testSeedVinculaSubcategoriasAsCategoriasCertas() throws {
        try aplicarSeed()

        let renda = try categoria(id: SeedIDs.idRenda)
        XCTAssertEqual(renda?.nome, "Renda")
        XCTAssertEqual(renda?.subcategorias?.count, 6)
        XCTAssertTrue(renda?.subcategorias?.contains { $0.id == SeedIDs.idSubSalario } ?? false)
    }

    func testSeedComLocaleInglesCriaNomesEmIngles() throws {
        try aplicarSeed(locale: Locale(identifier: "en_US"))

        let renda = try categoria(id: SeedIDs.idRenda)
        XCTAssertEqual(renda?.nome, "Income")
        XCTAssertTrue(renda?.subcategorias?.contains { $0.nome == "Salary" } ?? false)
    }

    func testSeedNovaVersaoAdicionaSoItensNovos() throws {
        let diversos = CategoriaModel(id: SeedIDs.idDiversos, nome: "Diversos", icon: "puzzlepiece", red: 0.35, green: 0.2, blue: 0.1)
        let custos = SubcategoriaModel(id: SeedIDs.idSubCustosBancarios, nome: "Custos Bancários", icon: "dollarsign", categoria: diversos)
        context.insert(diversos)
        context.insert(custos)
        try context.save()

        try aplicarSeed()

        let subIDs = Set(try context.fetch(FetchDescriptor<SubcategoriaModel>()).map(\.id))
        XCTAssertTrue(subIDs.contains(SeedIDs.idSubReserva), "Reserva entrou na versão 2 do catálogo")
        XCTAssertFalse(subIDs.contains(SeedIDs.idSubRoupas), "Itens da versão 1 ausentes foram apagados pelo usuário")
        XCTAssertNil(try categoria(id: SeedIDs.idTransporte))
        XCTAssertEqual((try categoria(id: SeedIDs.idDiversos))?.subcategorias?.first { $0.id == SeedIDs.idSubReserva }?.nome, "Reserva")
    }

    func testSeedNaoRessuscitaItemApagado() throws {
        try aplicarSeed()
        let transporte = try XCTUnwrap(try categoria(id: SeedIDs.idTransporte))
        let editor = CategoriaEditorViewModel(repository: SwiftDataCategoriaRepository(context: context))

        try editor.apagarCategoria(transporte)
        try aplicarSeed()

        XCTAssertNil(try categoria(id: SeedIDs.idTransporte))
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<SeedRemocaoModel>()), 1)
    }

    func testSeedNaoRecriaItemComLapideNumStoreVazio() throws {
        context.insert(SeedRemocaoModel(seedID: SeedIDs.idTransporte))
        try context.save()

        try aplicarSeed()

        XCTAssertNil(try categoria(id: SeedIDs.idTransporte))
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<CategoriaModel>()), 6)
    }

    func testApagarSubcategoriaForaDoSeedNaoCriaLapide() throws {
        try aplicarSeed()
        let editor = CategoriaEditorViewModel(repository: SwiftDataCategoriaRepository(context: context))
        let lazer = try XCTUnwrap(try categoria(id: SeedIDs.idEntretenimento))
        let jogos = try editor.criarSubcategoria(em: lazer, nome: "Jogos", icone: "gamecontroller")

        try editor.apagarSubcategoria(jogos)

        XCTAssertEqual(try context.fetchCount(FetchDescriptor<SeedRemocaoModel>()), 0)
    }
}
