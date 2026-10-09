import SwiftData
import XCTest
@testable import CashUp

@MainActor
final class SwiftDataPlanningRepositoryTests: XCTestCase {
    private var container: ModelContainer!
    private var context: ModelContext!
    private var sut: SwiftDataPlanningRepository!

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
        sut = SwiftDataPlanningRepository(context: context)
    }

    override func tearDownWithError() throws {
        container = nil
        context = nil
        sut = nil
    }

    func testInserirEBuscarCategoriasPlanejadasPorMes() throws {
        let mes = Date.make(year: 2026, month: 3, day: 1)
        let outroMes = Date.make(year: 2026, month: 4, day: 1)

        let cat = CategoriaModel(id: UUID(), nome: "Moradia", icon: "house", red: 0.1, green: 0.2, blue: 0.3)
        context.insert(cat)

        let plano1 = CategoriaPlanejadaModel(mesAno: mes, categoriaOriginal: cat)
        let plano2 = CategoriaPlanejadaModel(mesAno: outroMes, categoriaOriginal: cat)

        sut.insert(plano1)
        sut.insert(plano2)
        try sut.save()

        let planosMarco = try sut.fetchCategoriasPlanejadas(mes: mes)
        XCTAssertEqual(planosMarco.count, 1)
        XCTAssertEqual(planosMarco.first?.categoriaOriginal?.nome, "Moradia")
    }

    func testBuscarCategoriaPlanejadaEspecifica() throws {
        let mes = Date.make(year: 2026, month: 3, day: 1)
        let catID = UUID()
        let cat = CategoriaModel(id: catID, nome: "Educação", icon: "book", red: 0.2, green: 0.3, blue: 0.4)
        context.insert(cat)

        let plano = CategoriaPlanejadaModel(mesAno: mes, categoriaOriginal: cat)
        sut.insert(plano)
        try sut.save()

        let encontrado = try sut.fetchCategoriaPlanejada(mes: mes, categoriaID: catID)
        XCTAssertNotNil(encontrado)

        let naoEncontrado = try sut.fetchCategoriaPlanejada(mes: mes, categoriaID: UUID())
        XCTAssertNil(naoEncontrado)
    }

    func testDeletarCategoriaESubcategoriaPlanejada() throws {
        let mes = Date.make(year: 2026, month: 3, day: 1)
        let cat = CategoriaModel(id: UUID(), nome: "Lazer", icon: "gamecontroller", red: 0, green: 0, blue: 1)
        let sub = SubcategoriaModel(nome: "Cinema", icon: "film", categoria: cat, usageCount: 0)
        context.insert(cat)
        context.insert(sub)

        let plano = CategoriaPlanejadaModel(mesAno: mes, categoriaOriginal: cat)
        let subPlano = SubcategoriaPlanejadaModel(valorPlanejado: 200.0, subcategoriaOriginal: sub, categoriaPlanejada: plano)
        plano.subcategoriasPlanejadas = [subPlano]

        sut.insert(plano)
        try sut.save()

        sut.delete(subPlano)
        try sut.save()
        XCTAssertNil(try sut.fetchSubcategoriaPlanejada(id: subPlano.id))

        sut.delete(plano)
        try sut.save()
        XCTAssertTrue(try sut.fetchCategoriasPlanejadas(mes: mes).isEmpty)
    }
}
