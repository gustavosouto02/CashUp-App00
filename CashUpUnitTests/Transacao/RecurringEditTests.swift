import XCTest
import SwiftData
@testable import CashUp

@MainActor
final class RecurringEditTests: XCTestCase {
    private var container: ModelContainer!
    private var context: ModelContext!
    private var viewModel: ExpensesViewModel!
    private var categoria: CategoriaModel!
    private var subcategoria: SubcategoriaModel!
    private let calendar = Calendar.current

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
        categoria = CategoriaModel(nome: "Lazer", icon: "gamecontroller", red: 0.8, green: 0.2, blue: 0.3)
        subcategoria = SubcategoriaModel(nome: "Cinema", icon: "film.fill", categoria: categoria)
        context.insert(categoria)
        context.insert(subcategoria)
        try context.save()
        viewModel = ExpensesViewModel(modelContext: context)
    }

    override func tearDownWithError() throws {
        viewModel = nil
        context = nil
        container = nil
        try super.tearDownWithError()
    }

    private func inserirSerieMensal(inicio: Date, valor: Double = 100.0) throws -> ExpenseModel {
        let serie = ExpenseModel(
            amount: valor,
            date: inicio,
            expenseDescription: "Mensalidade",
            isIncome: false,
            repetition: RepetitionData(repeatOption: .mensalmente, endDate: nil),
            categoria: categoria,
            subcategoria: subcategoria
        )
        context.insert(serie)
        try context.save()
        return serie
    }

    private func ocorrenciaExibida(em mes: Date) throws -> DisplayableExpense {
        viewModel.currentMonth = mes
        viewModel.loadDisplayableExpenses()
        return try XCTUnwrap(viewModel.transacoesExibidas.first)
    }

    private func todasTransacoesPersistidas() throws -> [ExpenseModel] {
        try context.fetch(FetchDescriptor<ExpenseModel>())
    }

    func testEditarSomenteEstaOcorrenciaIsolaTransacaoEPreservaSerie() throws {
        let inicio = Date.make(year: 2026, month: 1, day: 10)
        let serieOriginal = try inserirSerieMensal(inicio: inicio, valor: 100.0)

        let mesFevereiro = Date.make(year: 2026, month: 2, day: 1)
        let ocorrenciaFev = try ocorrenciaExibida(em: mesFevereiro)

        let edit = ExpenseEdit(
            amount: 150.0,
            date: ocorrenciaFev.date,
            description: "Mensalidade com taxa",
            isIncome: false,
            categoria: categoria,
            subcategoria: subcategoria,
            repetition: nil
        )

        try viewModel.editRecurring(ocorrenciaFev, scope: .thisOccurrenceOnly, edit: edit)

        let persistidas = try todasTransacoesPersistidas()
        XCTAssertEqual(persistidas.count, 2)

        let dataExcluidaEsperada = calendar.startOfDay(for: Date.make(year: 2026, month: 2, day: 10))
        XCTAssertEqual(serieOriginal.repetition?.excludedDates, [dataExcluidaEsperada])

        let isolada = try XCTUnwrap(persistidas.first { $0.id != serieOriginal.id })
        XCTAssertEqual(isolada.amount, 150.0)
        XCTAssertEqual(isolada.expenseDescription, "Mensalidade com taxa")
        XCTAssertNil(isolada.repetition)

        viewModel.currentMonth = mesFevereiro
        viewModel.loadDisplayableExpenses()
        XCTAssertEqual(viewModel.transacoesExibidas.count, 1)
        XCTAssertEqual(viewModel.transacoesExibidas.first?.amount, 150.0)

        let mesMarco = Date.make(year: 2026, month: 3, day: 1)
        viewModel.currentMonth = mesMarco
        viewModel.loadDisplayableExpenses()
        XCTAssertEqual(viewModel.transacoesExibidas.count, 1)
        XCTAssertEqual(viewModel.transacoesExibidas.first?.amount, 100.0)
    }

    func testEditarEstaEFuturasEncerraSerieAnteriorECriaNovaSerie() throws {
        let inicio = Date.make(year: 2026, month: 1, day: 10)
        let serieOriginal = try inserirSerieMensal(inicio: inicio, valor: 100.0)

        let mesMarco = Date.make(year: 2026, month: 3, day: 1)
        let ocorrenciaMarco = try ocorrenciaExibida(em: mesMarco)

        let novaData = Date.make(year: 2026, month: 3, day: 15)
        let edit = ExpenseEdit(
            amount: 180.0,
            date: novaData,
            description: "Plano Atualizado",
            isIncome: false,
            categoria: categoria,
            subcategoria: subcategoria,
            repetition: RepetitionData(repeatOption: .mensalmente, endDate: nil)
        )

        try viewModel.editRecurring(ocorrenciaMarco, scope: .thisAndAllFutureOccurrences, edit: edit)

        let persistidas = try todasTransacoesPersistidas()
        XCTAssertEqual(persistidas.count, 2)

        let fimEsperadoOriginal = calendar.startOfDay(for: Date.make(year: 2026, month: 3, day: 9))
        XCTAssertEqual(serieOriginal.repetition?.endDate, fimEsperadoOriginal)

        let novaSerie = try XCTUnwrap(persistidas.first { $0.id != serieOriginal.id })
        XCTAssertEqual(novaSerie.amount, 180.0)
        XCTAssertEqual(novaSerie.date, novaData)
        XCTAssertEqual(novaSerie.repetition?.repeatOption, .mensalmente)

        let mesAbril = Date.make(year: 2026, month: 4, day: 1)
        viewModel.currentMonth = mesAbril
        viewModel.loadDisplayableExpenses()
        XCTAssertEqual(viewModel.transacoesExibidas.count, 1)
        XCTAssertEqual(viewModel.transacoesExibidas.first?.amount, 180.0)
    }

    func testEditarEstaEFuturasNaPrimeiraOcorrenciaAtualizaOriginalDiretamente() throws {
        let inicio = Date.make(year: 2026, month: 1, day: 10)
        let serieOriginal = try inserirSerieMensal(inicio: inicio, valor: 100.0)

        let mesJaneiro = Date.make(year: 2026, month: 1, day: 1)
        let primeiraOcorrencia = try ocorrenciaExibida(em: mesJaneiro)

        let edit = ExpenseEdit(
            amount: 130.0,
            date: Date.make(year: 2026, month: 1, day: 12),
            description: "Primeiro Ajustado",
            isIncome: false,
            categoria: categoria,
            subcategoria: subcategoria,
            repetition: RepetitionData(repeatOption: .mensalmente, endDate: nil)
        )

        try viewModel.editRecurring(primeiraOcorrencia, scope: .thisAndAllFutureOccurrences, edit: edit)

        let persistidas = try todasTransacoesPersistidas()
        XCTAssertEqual(persistidas.count, 1)
        XCTAssertEqual(persistidas.first?.id, serieOriginal.id)
        XCTAssertEqual(serieOriginal.amount, 130.0)
        XCTAssertEqual(serieOriginal.expenseDescription, "Primeiro Ajustado")
        XCTAssertEqual(serieOriginal.date, Date.make(year: 2026, month: 1, day: 12))
    }

    func testEditarTodaASerieModificaOriginalSemCriarNovasTransacoes() throws {
        let inicio = Date.make(year: 2026, month: 1, day: 10)
        let serieOriginal = try inserirSerieMensal(inicio: inicio, valor: 100.0)

        let mesFevereiro = Date.make(year: 2026, month: 2, day: 1)
        let ocorrenciaFev = try ocorrenciaExibida(em: mesFevereiro)

        let edit = ExpenseEdit(
            amount: 220.0,
            date: inicio,
            description: "Série Inteira Reajustada",
            isIncome: false,
            categoria: categoria,
            subcategoria: subcategoria,
            repetition: RepetitionData(repeatOption: .mensalmente, endDate: nil)
        )

        try viewModel.editRecurring(ocorrenciaFev, scope: .entireSeries, edit: edit)

        let persistidas = try todasTransacoesPersistidas()
        XCTAssertEqual(persistidas.count, 1)
        XCTAssertEqual(serieOriginal.amount, 220.0)
        XCTAssertEqual(serieOriginal.expenseDescription, "Série Inteira Reajustada")
    }

    func testEditarTransacaoNaoRecorrenteAtualizaDiretamente() throws {
        let unica = ExpenseModel(
            amount: 75.0,
            date: Date.make(year: 2026, month: 3, day: 14),
            expenseDescription: "Almoço",
            categoria: categoria,
            subcategoria: subcategoria
        )
        context.insert(unica)
        try context.save()

        let ocorrencia = DisplayableExpense(from: unica)
        let edit = ExpenseEdit(
            amount: 85.0,
            date: Date.make(year: 2026, month: 3, day: 14),
            description: "Almoço com sobremesa",
            isIncome: false,
            categoria: categoria,
            subcategoria: subcategoria,
            repetition: nil
        )

        try viewModel.editRecurring(ocorrencia, scope: .thisOccurrenceOnly, edit: edit)

        let persistidas = try todasTransacoesPersistidas()
        XCTAssertEqual(persistidas.count, 1)
        XCTAssertEqual(unica.amount, 85.0)
        XCTAssertEqual(unica.expenseDescription, "Almoço com sobremesa")
    }
}
