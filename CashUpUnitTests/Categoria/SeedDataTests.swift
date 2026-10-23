import SwiftData
import XCTest

@testable import CashUp

@MainActor
final class SeedDataTests: XCTestCase {
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

    func testSeedExecutadoDuasVezesNaoDuplicaDados() async throws {
        await popularDadosIniciaisSeNecessario(modelContext: context, locale: Locale(identifier: "pt_BR"))
        await popularDadosIniciaisSeNecessario(modelContext: context, locale: Locale(identifier: "pt_BR"))

        XCTAssertEqual(try context.fetchCount(FetchDescriptor<CategoriaModel>()), 7)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<SubcategoriaModel>()), 72)
    }

    func testSeedVinculaSubcategoriasAsCategoriasCertas() async throws {
        await popularDadosIniciaisSeNecessario(modelContext: context, locale: Locale(identifier: "pt_BR"))

        let rendaID = SeedIDs.idRenda
        let renda = try context.fetch(FetchDescriptor<CategoriaModel>(predicate: #Predicate { $0.id == rendaID })).first
        XCTAssertEqual(renda?.nome, "Renda")
        XCTAssertEqual(renda?.subcategorias.count, 6)
        XCTAssertTrue(renda?.subcategorias.contains { $0.id == SeedIDs.idSubSalario } ?? false)
    }

    func testSeedAtualizaCategoriasExistentesComNovasSubcategorias() async throws {
        // Simula usuário antigo que já possui a categoria Diversos sem a subcategoria Reserva
        let diversos = CategoriaModel(id: SeedIDs.idDiversos, nome: "Diversos", icon: "puzzlepiece", red: 0.35, green: 0.2, blue: 0.1)
        let subAntiga = SubcategoriaModel(id: SeedIDs.idSubCustosBancarios, nome: "Custos Bancários", icon: "dollarsign", categoria: diversos)
        diversos.subcategorias = [subAntiga]
        context.insert(diversos)
        try context.save()

        // Executa o seed como no lançamento da nova versão
        await popularDadosIniciaisSeNecessario(modelContext: context, locale: Locale(identifier: "pt_BR"))

        let diversosID = SeedIDs.idDiversos
        let diversosAtualizado = try context.fetch(FetchDescriptor<CategoriaModel>(predicate: #Predicate { $0.id == diversosID })).first
        let temReserva = diversosAtualizado?.subcategorias.contains { $0.id == SeedIDs.idSubReserva } ?? false

        XCTAssertTrue(temReserva)
        XCTAssertEqual(diversosAtualizado?.subcategorias.first(where: { $0.id == SeedIDs.idSubReserva })?.nome, "Reserva")
    }

    func testSeedComLocaleInglesCriaNomesEmIngles() async throws {
        await popularDadosIniciaisSeNecessario(modelContext: context, locale: Locale(identifier: "en_US"))

        let rendaID = SeedIDs.idRenda
        let renda = try context.fetch(FetchDescriptor<CategoriaModel>(predicate: #Predicate { $0.id == rendaID })).first
        XCTAssertEqual(renda?.nome, "Income")
        XCTAssertTrue(renda?.subcategorias.contains { $0.nome == "Salary" } ?? false)
    }
}
