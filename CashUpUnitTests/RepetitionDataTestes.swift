//
//  RepetitionDataTestes.swift
//  CashUpUnitTests
//
//  Created by Gustavo Souto Pereira on 10/03/26.
//

import Foundation
import SwiftData
import XCTest

@testable import CashUp

@MainActor
final class RepetitionDataTestes: XCTestCase {

    var calendar = Calendar.current.self
    var date = Date()
    var expenseViewModel: ExpensesViewModel!
    var repetition: RepetitionData!
    var container: ModelContainer!
    var context: ModelContext!

    @MainActor
    override func setUpWithError() throws {
        calendar = Calendar.current
        date = Date()
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(
            for: ExpenseModel.self,
            CategoriaModel.self,
            SubcategoriaModel.self,
            configurations: config
        )
        context = ModelContext(container)
        expenseViewModel = ExpensesViewModel(modelContext: context)
    }

    override func tearDownWithError() throws {
        expenseViewModel = nil
        context = nil
        container = nil
    }

    // model mínimo pra testes
    private func makeExpense(date: Date, repetition: RepetitionData?)
        -> ExpenseModel
    {
        ExpenseModel(
            amount: 100.0,
            date: date,
            expenseDescription: "Teste",
            isIncome: false,
            repetition: repetition,
            categoria: nil,
            subcategoria: nil
        )
    }

    // model para testes no context
    @discardableResult
    private func insertExpense(date: Date, repetition: RepetitionData?) throws
        -> ExpenseModel
    {
        let expense = makeExpense(date: date, repetition: repetition)

        context.insert(expense)
        try context.save()

        return expense
    }

    func interval(year: Int, month: Int) -> DateInterval {
        let start = Date.make(year: year, month: month, day: 1)
        guard let range = calendar.dateInterval(of: .month, for: start) else {
            fatalError("Intervalo inválido")
        }
        return range
    }

    // Despesa sem repetição de data, deve aparecer apenas uma vez no próprio mês, em nenhum outro
    func test_ExpenseOnlyInMonth() {

        let expense = makeExpense(date: date, repetition: nil)

        let month = interval(year: 2026, month: 3)

        let ocorruncesMonth = expense.generateOccurrences(
            forDateInterval: month,
            calendar: calendar
        )
        XCTAssertEqual(ocorruncesMonth.count, 1)

        let april = interval(year: 2026, month: 4)

        let occurreces = expense.generateOccurrences(
            forDateInterval: april,
            calendar: calendar
        )
        XCTAssertNotEqual(occurreces.count, 1)

    }

    // Recorrência mensal deve aparecer na data correta em outros meses

    func test_MonthlyRepeatedExpenseOnDay() throws {
        let startDate = Date.make(year: 2026, month: 2, day: 10)
        let repetition = RepetitionData(
            repeatOption: .mensalmente,
            endDate: nil
        )
        _ = try insertExpense(date: startDate, repetition: repetition)

        expenseViewModel.currentMonth = Date.make(year: 2026, month: 3, day: 1)

        let targetDate = Date.make(year: 2026, month: 3, day: 10)

        let results = expenseViewModel.fetchTransactions(
            forSpecificDate: targetDate,
            isIncome: nil
        )

        XCTAssertEqual(
            results.count,
            1,
            "A despensa mensal deveria aparecer no dia 10 de março"
        )

        if let occurrence = results.first {
            let day = calendar.component(.day, from: occurrence.date)
            XCTAssertEqual(
                day,
                10,
                "A ocorrência deve cair exatamente no dia 10"
            )
        }
    }

    func test_WeeklyOcurrence() {
        let expense = makeExpense(
            date: date,
            repetition: RepetitionData(
                repeatOption: .semanalmente,
                endDate: nil
            )
        )

        let march = interval(year: 2026, month: 3)
        let ocurrences = expense.generateOccurrences(
            forDateInterval: march,
            calendar: calendar
        )
        .sorted { $0.date < $1.date }

        for i in 1..<ocurrences.count {
            let days = calendar.dateComponents(
                [.day],
                from: calendar.startOfDay(for: ocurrences[i - 1].date),
                to: calendar.startOfDay(for: ocurrences[i].date)
            ).day!

            XCTAssertEqual(
                days,
                7,
                "Cada ocorrência deve ser consecutiva e ter exatamente 7 dias de diferença"
            )
            print(
                "Ocorrência \(i) e \(i+1) devem ter exatamente \(days) dias de diferença "
            )
        }
    }
}

extension Date {
    static func make(year: Int, month: Int, day: Int) -> Date {
        var c = DateComponents()
        c.year = year
        c.month = month
        c.day = day
        c.hour = 12
        c.minute = 0
        c.second = 0
        return Calendar.current.date(from: c)!
    }

    func startOfMonth() -> Date {
        let cal = Calendar.current
        return cal.date(from: cal.dateComponents([.year, .month], from: self))!
    }
}
