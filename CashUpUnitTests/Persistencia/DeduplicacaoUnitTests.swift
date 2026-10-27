import SwiftData
import XCTest

@testable import CashUp

final class DeduplicacaoUnitTests: XCTestCase {
    private var container: ModelContainer!
    private var context: ModelContext!
    private let servico = DeduplicacaoService()

    private let idTransporte = UUID()
    private let idOnibus = UUID()
    private let marco = Date.make(year: 2026, month: 3, day: 10)
    private let antes = Date.make(year: 2026, month: 1, day: 1)
    private let depois = Date.make(year: 2026, month: 2, day: 1)

    override func setUpWithError() throws {
        try super.setUpWithError()
        container = try CashUpPersistence.makeContainer(inMemory: true)
        context = ModelContext(container)
    }

    override func tearDownWithError() throws {
        context = nil
        container = nil
    }

    private func copiaCategoria(nome: String = "Transporte", criadoEm: Date, atualizadoEm: Date? = nil) -> CategoriaModel {
        let categoria = CategoriaModel(id: idTransporte, nome: nome, icon: "car", red: 0.75, green: 0.35, blue: 0.98)
        categoria.criadoEm = criadoEm
        categoria.atualizadoEm = atualizadoEm ?? criadoEm
        context.insert(categoria)
        return categoria
    }

    private func copiaSubcategoria(em categoria: CategoriaModel, criadoEm: Date, usageCount: Int = 0) -> SubcategoriaModel {
        let subcategoria = SubcategoriaModel(id: idOnibus, nome: "Ônibus", icon: "bus", categoria: categoria, usageCount: usageCount)
        subcategoria.criadoEm = criadoEm
        subcategoria.atualizadoEm = criadoEm
        context.insert(subcategoria)
        return subcategoria
    }

    private func transacao(_ categoria: CategoriaModel?, _ subcategoria: SubcategoriaModel?, valor: Double = 10) -> ExpenseModel {
        let transacao = ExpenseModel(amount: valor, date: marco, categoria: categoria, subcategoria: subcategoria)
        context.insert(transacao)
        return transacao
    }

    private func categorias() throws -> [CategoriaModel] {
        try context.fetch(FetchDescriptor<CategoriaModel>())
    }

    func testDeduplicaCategoriaReapontaTransacoes() throws {
        let original = copiaCategoria(criadoEm: antes)
        let copia = copiaCategoria(criadoEm: depois)
        let subOriginal = copiaSubcategoria(em: original, criadoEm: antes)
        _ = transacao(original, subOriginal)
        _ = transacao(copia, nil)
        let planejada = CategoriaPlanejadaModel(mesAno: marco, categoriaOriginal: copia)
        context.insert(planejada)
        try context.save()

        XCTAssertTrue(try servico.deduplicar(em: context))

        let restantes = try categorias()
        XCTAssertEqual(restantes.count, 1)
        XCTAssertEqual(restantes.first?.persistentModelID, original.persistentModelID)
        let transacoes = try context.fetch(FetchDescriptor<ExpenseModel>())
        XCTAssertEqual(transacoes.count, 2)
        XCTAssertTrue(transacoes.allSatisfy { $0.categoria?.persistentModelID == original.persistentModelID })
        XCTAssertEqual(planejada.categoriaOriginal?.persistentModelID, original.persistentModelID)
    }

    func testDeduplicaSubcategoriaSomaUsageCountEReapontaTransacoes() throws {
        let categoria = copiaCategoria(criadoEm: antes)
        let original = copiaSubcategoria(em: categoria, criadoEm: antes, usageCount: 2)
        let copia = copiaSubcategoria(em: categoria, criadoEm: depois, usageCount: 3)
        _ = transacao(categoria, copia)
        let planejada = SubcategoriaPlanejadaModel(valorPlanejado: 100, subcategoriaOriginal: copia)
        context.insert(planejada)
        try context.save()

        try servico.deduplicar(em: context)

        let subcategorias = try context.fetch(FetchDescriptor<SubcategoriaModel>())
        XCTAssertEqual(subcategorias.count, 1)
        XCTAssertEqual(subcategorias.first?.persistentModelID, original.persistentModelID)
        XCTAssertEqual(original.usageCount, 5)
        XCTAssertEqual(try context.fetch(FetchDescriptor<ExpenseModel>()).first?.subcategoria?.persistentModelID, original.persistentModelID)
        XCTAssertEqual(planejada.subcategoriaOriginal?.persistentModelID, original.persistentModelID)
    }

    func testSobreviventeEhDeterministico() throws {
        let copias = (0..<5).map { _ in copiaCategoria(criadoEm: .distantPast) }
        try context.save()
        let esperado = copias.min { $0.instanciaID.uuidString < $1.instanciaID.uuidString }?.instanciaID

        for _ in 0..<100 {
            let embaralhadas = copias.shuffled()
            let menor = embaralhadas.sorted { ($0.criadoEm, $0.instanciaID.uuidString) < ($1.criadoEm, $1.instanciaID.uuidString) }.first
            XCTAssertEqual(menor?.instanciaID, esperado)
        }

        try servico.deduplicar(em: context)

        XCTAssertEqual(try categorias().map(\.instanciaID), [esperado])
    }

    func testCamposVemDoMaisRecente() throws {
        let original = copiaCategoria(nome: "Transporte", criadoEm: antes)
        _ = copiaCategoria(nome: "Mobilidade", criadoEm: depois, atualizadoEm: depois.addingTimeInterval(60))
        try context.save()

        try servico.deduplicar(em: context)

        XCTAssertEqual(try categorias().count, 1)
        XCTAssertEqual(original.nome, "Mobilidade")
    }

    func testDeduplicaPlanejamentoDoMesmoMes() throws {
        let categoria = copiaCategoria(criadoEm: antes)
        let subcategoria = copiaSubcategoria(em: categoria, criadoEm: antes)
        let planoA = CategoriaPlanejadaModel(mesAno: marco, categoriaOriginal: categoria)
        let planoB = CategoriaPlanejadaModel(mesAno: marco, categoriaOriginal: categoria)
        planoA.criadoEm = antes
        planoB.criadoEm = depois
        let itemA = SubcategoriaPlanejadaModel(valorPlanejado: 100, subcategoriaOriginal: subcategoria, categoriaPlanejada: planoA)
        let itemB = SubcategoriaPlanejadaModel(valorPlanejado: 250, subcategoriaOriginal: subcategoria, categoriaPlanejada: planoB)
        itemA.atualizadoEm = antes
        itemB.atualizadoEm = depois
        [planoA, planoB].forEach(context.insert)
        [itemA, itemB].forEach(context.insert)
        try context.save()

        try servico.deduplicar(em: context)

        let planos = try context.fetch(FetchDescriptor<CategoriaPlanejadaModel>())
        XCTAssertEqual(planos.count, 1, "RN-09: um planejamento por categoria e mês")
        let itens = try context.fetch(FetchDescriptor<SubcategoriaPlanejadaModel>())
        XCTAssertEqual(itens.count, 1, "RN-10: uma subcategoria por planejamento")
        XCTAssertEqual(itens.first?.valorPlanejado, 250)
        XCTAssertEqual(planos.first?.valorTotalPlanejado, 250)
    }

    func testDeduplicaTransacoesDoMesmoID() throws {
        let id = UUID()
        [antes, depois].forEach { criadoEm in
            let copia = ExpenseModel(id: id, amount: 10, date: marco)
            copia.criadoEm = criadoEm
            context.insert(copia)
        }
        try context.save()

        try servico.deduplicar(em: context)

        let transacoes = try context.fetch(FetchDescriptor<ExpenseModel>())
        XCTAssertEqual(transacoes.count, 1)
        XCTAssertEqual(transacoes.first?.criadoEm, antes)
    }

    func testDeduplicacaoIdempotente() throws {
        let categoria = copiaCategoria(criadoEm: antes)
        _ = copiaCategoria(criadoEm: depois)
        _ = transacao(categoria, nil)
        try context.save()

        XCTAssertTrue(try servico.deduplicar(em: context))
        XCTAssertFalse(try servico.deduplicar(em: context))
        XCTAssertEqual(try categorias().count, 1)
    }

    func testLapideRemoveSeedSemTransacoes() throws {
        let transporte = CategoriaModel(id: SeedIDs.idTransporte, nome: "Transporte", icon: "car", red: 0, green: 0, blue: 0)
        context.insert(transporte)
        context.insert(SubcategoriaModel(id: SeedIDs.idSubTaxi, nome: "Táxi", icon: "car", categoria: transporte))
        context.insert(SeedRemocaoModel(seedID: SeedIDs.idTransporte))
        context.insert(SeedRemocaoModel(seedID: SeedIDs.idTransporte))
        try context.save()

        try servico.deduplicar(em: context)

        XCTAssertTrue(try categorias().isEmpty)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<SubcategoriaModel>()), 0)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<SeedRemocaoModel>()), 1, "A lápide fica para os outros aparelhos")
    }

    func testLapideNaoRemoveSeedComTransacoes() throws {
        let transporte = CategoriaModel(id: SeedIDs.idTransporte, nome: "Transporte", icon: "car", red: 0, green: 0, blue: 0)
        let taxi = SubcategoriaModel(id: SeedIDs.idSubTaxi, nome: "Táxi", icon: "car", categoria: transporte)
        context.insert(transporte)
        context.insert(taxi)
        _ = transacao(transporte, taxi)
        context.insert(SeedRemocaoModel(seedID: SeedIDs.idTransporte))
        try context.save()

        try servico.deduplicar(em: context)

        XCTAssertEqual(try categorias().count, 1)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<SeedRemocaoModel>()), 0, "O uso real vence a remoção")
    }

    func testLapideNaoRemoveRenda() throws {
        context.insert(CategoriaModel(id: SeedIDs.idRenda, nome: "Renda", icon: "dollarsign", red: 0, green: 0, blue: 0))
        context.insert(SeedRemocaoModel(seedID: SeedIDs.idRenda))
        try context.save()

        try servico.deduplicar(em: context)

        XCTAssertEqual(try categorias().count, 1)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<SeedRemocaoModel>()), 0)
    }

    func testSemDuplicatasNaoAlteraNada() throws {
        let categoria = copiaCategoria(criadoEm: antes)
        _ = copiaSubcategoria(em: categoria, criadoEm: antes)
        try context.save()

        XCTAssertFalse(try servico.deduplicar(em: context))
    }
}
