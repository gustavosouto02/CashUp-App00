import XCTest
@testable import CashUp

final class GenerateOccurrencesBoundsTests: XCTestCase {
    private let calendar = Calendar.current

    private func monthInterval(year: Int, month: Int) -> DateInterval {
        calendar.dateInterval(of: .month, for: Date.make(year: year, month: month, day: 1))!
    }

    private func makeExpense(date: Date, repetition: RepetitionData?) -> ExpenseModel {
        ExpenseModel(amount: 50, date: date, expenseDescription: "Teste", repetition: repetition)
    }

    func testSerieDiariaComFimDistanteGeraNoMaximoUmMes() {
        let inicio = Date.make(year: 2026, month: 1, day: 1)
        let fim = Date.make(year: 2126, month: 1, day: 1)
        let expense = makeExpense(date: inicio, repetition: RepetitionData(repeatOption: .diariamente, endDate: fim))

        let occurrences = expense.generateOccurrences(forDateInterval: monthInterval(year: 2026, month: 3), calendar: calendar)

        XCTAssertEqual(occurrences.count, 31)
    }

    func testSerieDiariaComFimDistanteRespondeRapido() {
        let inicio = Date.make(year: 2026, month: 1, day: 1)
        let fim = Date.make(year: 2126, month: 1, day: 1)
        let expense = makeExpense(date: inicio, repetition: RepetitionData(repeatOption: .diariamente, endDate: fim))
        let interval = monthInterval(year: 2026, month: 3)

        measure {
            _ = expense.generateOccurrences(forDateInterval: interval, calendar: calendar)
        }
    }

    func testSerieSemFimComDataFuturaNaoGeraAntesDoInicio() {
        let inicio = Date.make(year: 2026, month: 3, day: 20)
        let expense = makeExpense(date: inicio, repetition: RepetitionData(repeatOption: .diariamente, endDate: nil))

        let occurrences = expense.generateOccurrences(forDateInterval: monthInterval(year: 2026, month: 3), calendar: calendar)

        XCTAssertEqual(occurrences.count, 12)
        XCTAssertEqual(occurrences.first?.date, inicio)
    }

    func testDataFimNoUltimoDiaDoMesIncluiUltimaOcorrencia() {
        let inicio = Date.make(year: 2026, month: 3, day: 1)
        let fim = Date.make(year: 2026, month: 3, day: 31)
        let expense = makeExpense(date: inicio, repetition: RepetitionData(repeatOption: .diariamente, endDate: fim))

        let occurrences = expense.generateOccurrences(forDateInterval: monthInterval(year: 2026, month: 3), calendar: calendar)

        XCTAssertEqual(occurrences.count, 31)
        XCTAssertEqual(occurrences.last.map { calendar.component(.day, from: $0.date) }, 31)
    }

    func testDataFimAnteriorAoMesConsultadoNaoGeraNada() {
        let inicio = Date.make(year: 2026, month: 1, day: 1)
        let fim = Date.make(year: 2026, month: 2, day: 15)
        let expense = makeExpense(date: inicio, repetition: RepetitionData(repeatOption: .semanalmente, endDate: fim))

        let occurrences = expense.generateOccurrences(forDateInterval: monthInterval(year: 2026, month: 3), calendar: calendar)

        XCTAssertTrue(occurrences.isEmpty)
    }

    func testDatasExcluidasSaoIgnoradas() {
        let inicio = Date.make(year: 2026, month: 1, day: 10)
        let excluida = Date.make(year: 2026, month: 3, day: 10)
        let expense = makeExpense(date: inicio, repetition: RepetitionData(repeatOption: .mensalmente, endDate: nil, excludedDates: [excluida]))

        let marco = expense.generateOccurrences(forDateInterval: monthInterval(year: 2026, month: 3), calendar: calendar)
        let abril = expense.generateOccurrences(forDateInterval: monthInterval(year: 2026, month: 4), calendar: calendar)

        XCTAssertTrue(marco.isEmpty)
        XCTAssertEqual(abril.count, 1)
    }
}
