import SwiftData
import XCTest

@testable import CashUp

@MainActor
final class PreparacaoDeDadosIniciaisTests: XCTestCase {
    private var container: ModelContainer!
    private var context: ModelContext!
    private var settings: InMemoryAppSettings!

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

    func testFallbackEmMemoriaNaoRodaSeedNemGravaAVersao() throws {
        PreparacaoDeDadosIniciais.executar(em: context, settings: settings, usandoFallbackEmMemoria: true)

        XCTAssertEqual(settings.seedVersaoAplicada, 0)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<CategoriaModel>()), 0)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<SubcategoriaModel>()), 0)
    }

    func testAberturaNormalRodaSeedEGravaAVersao() throws {
        PreparacaoDeDadosIniciais.executar(em: context, settings: settings, usandoFallbackEmMemoria: false)

        XCTAssertEqual(settings.seedVersaoAplicada, SeedCatalogo.versao)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<CategoriaModel>()), 7)
    }
}
