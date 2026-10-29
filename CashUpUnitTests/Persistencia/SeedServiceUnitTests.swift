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

    func testItensDoSeedNascemSemContarComoEdicao() throws {
        try aplicarSeed()

        let categorias = try context.fetch(FetchDescriptor<CategoriaModel>())
        let subcategorias = try context.fetch(FetchDescriptor<SubcategoriaModel>())
        XCTAssertTrue(categorias.allSatisfy { $0.atualizadoEm == .distantPast })
        XCTAssertTrue(subcategorias.allSatisfy { $0.atualizadoEm == .distantPast })
    }

    func testCopiaDoSeedNaoSobrescreveEdicao() throws {
        let edicao = Date.make(year: 2026, month: 2, day: 1)
        try aplicarSeed()
        let idDiversos = SeedIDs.idDiversos
        let idSubGeral = SeedIDs.idSubDiversosGerais
        let editada = CategoriaModel(id: SeedIDs.idDiversos, nome: "Outros", icon: "tray", red: 0.1, green: 0.2, blue: 0.3)
        editada.criadoEm = .distantPast
        editada.atualizadoEm = edicao
        let subEditada = SubcategoriaModel(id: SeedIDs.idSubDiversosGerais, nome: "Geral", icon: "tray", categoria: editada)
        subEditada.criadoEm = .distantPast
        subEditada.atualizadoEm = edicao
        context.insert(editada)
        context.insert(subEditada)
        try context.save()

        try DeduplicacaoService().deduplicar(em: context)

        let restantes = try context.fetch(FetchDescriptor<CategoriaModel>(predicate: #Predicate { $0.id == idDiversos }))
        XCTAssertEqual(restantes.count, 1)
        XCTAssertEqual(restantes.first?.nome, "Outros", "A renomeação do usuário vence a cópia criada pelo seed")
        XCTAssertEqual(restantes.first?.icon, "tray")
        XCTAssertEqual(restantes.first?.atualizadoEm, edicao)
        XCTAssertEqual(restantes.first?.instanciaID, editada.instanciaID, "criadoEm menor mantém a identidade")
        let subs = try context.fetch(FetchDescriptor<SubcategoriaModel>(predicate: #Predicate { $0.id == idSubGeral }))
        XCTAssertEqual(subs.count, 1)
        XCTAssertEqual(subs.first?.nome, "Geral")
    }

    func testSeedNaoCriaRendaSemSubcategoria() throws {
        let subsDaRenda = [SeedIDs.idSubInvestimentos, SeedIDs.idSubJuros, SeedIDs.idSubPensao,
                           SeedIDs.idSubRendaGeral, SeedIDs.idSubSalario, SeedIDs.idSubSalarioFamilia]
        subsDaRenda.forEach { context.insert(SeedRemocaoModel(seedID: $0)) }
        try context.save()

        try aplicarSeed()

        let renda = try XCTUnwrap(try categoria(id: SeedIDs.idRenda))
        XCTAssertEqual(renda.subcategorias?.map(\.id), [SeedIDs.idSubRendaGeral], "RN-08: a Renda sempre tem ao menos uma subcategoria")
    }
}
