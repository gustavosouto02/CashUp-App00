//
//  RepetitionIntegrationTestes.swift
//  CashUpUnitTests
//
//  Created by Gustavo Souto Pereira on 11/03/26.
//

import Foundation
import SwiftData
import XCTest

@testable import CashUp

@MainActor
final class RepetitionIntegrationTestes: XCTestCase {
    
    var calendar = Calendar.current.self
    var container: ModelContainer!
    var context: ModelContext!
    var expenseViewModel: ExpensesViewModel!
    
    @MainActor
    override func setUpWithError() throws {
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
    
    @discardableResult
    private func insertExpense(
        amount: Double = 100.0,
        date: Date,
        repeatOption: RepeatOption,
        endDate: Date? = nil,
        excludedDates: [Date]? = nil
    ) throws -> ExpenseModel {
        let repetition =
        repeatOption == .nunca
        ? nil
        : RepetitionData(
            repeatOption: repeatOption,
            endDate: endDate,
            excludedDates: excludedDates
        )
        
        let expense = ExpenseModel(
            amount: amount,
            date: date,
            expenseDescription: "Teste",
            isIncome: false,
            repetition: repetition,
            categoria: nil,
            subcategoria: nil
        )
        
        context.insert(expense)
        try context.save()
        return expense
    }
    
    private func intervaloMes(year: Int, month: Int) -> DateInterval {
        let start = Date.make(year: year, month: month, day: 1)
        guard let range = calendar.dateInterval(of: .month, for: start) else {
            fatalError("Intervalo inválido para \(month)/\(year)")
        }
        return range
    }
    
    private func ocorrencias(in intervalo: DateInterval) -> [DisplayableExpense]
    {
        let descriptor = FetchDescriptor<ExpenseModel>()
        let models = (try? context.fetch(descriptor)) ?? []
        return models.flatMap {
            $0.generateOccurrences(
                forDateInterval: intervalo,
                calendar: calendar
            )
        }
    }
    
    // teste remover despesa com .thisOcurrenceOnly
    func test_RemoveExpenseOnly() throws {
        
        // DADO uma despesa mensal no mês atual
        let date = Date()
        try insertExpense(date: date, repeatOption: .mensalmente)
        
        expenseViewModel.currentMonth = date
        expenseViewModel.loadDisplayableExpenses()
        
        guard let displayable = expenseViewModel.transacoesExibidas.first else {
            XCTFail("Nenhuma despesa carregada para deletar")
            return
        }
        
        // QUANDO o usuário exclui somente esta ocorrência
        expenseViewModel.removeExpense(displayable, scope: .thisOccurrenceOnly)
        
        // ENTÃO o model ainda existe no banco
        let modelsBanco = try context.fetch(FetchDescriptor<ExpenseModel>())
        
        XCTAssertEqual(
            modelsBanco.count,
            1,
            ".thisOccurrenceOnly não deve deletar o ExpenseModel do banco"
        )
        
        let excludedDates = modelsBanco.first?.repetition?.excludedDates ?? []
        XCTAssertFalse(
            excludedDates.isEmpty,
            "A data da ocorrência removida deve estar registrada em excludedDates"
        )
        
        let excluded = excludedDates.contains {
            calendar.isDate($0, inSameDayAs: displayable.date)
        }
        XCTAssertTrue(
            excluded,
            "A data exata da ocorrência removida deve constar em excludedDates"
        )
        
        // E não aparece mais na lista deste mês
        let existsInList = expenseViewModel.transacoesExibidas.contains {
            calendar.isDate($0.date, inSameDayAs: displayable.date)
        }
        XCTAssertFalse(
            existsInList,
            "A ocorrência excluída não deve reaparecer na lista do mês"
        )
        
    }
    
    func test_TotalDespesaMensal() throws {
        try insertExpense(
            amount: 39.90,
            date: Date.make(year: 2025, month: 1, day: 10),
            repeatOption: .mensalmente
        )
        try insertExpense(
            amount: 21.90,
            date: Date.make(year: 2025, month: 1, day: 5),
            repeatOption: .mensalmente
        )
        try insertExpense(
            amount: 27.90,
            date: Date.make(year: 2025, month: 1, day: 20),
            repeatOption: .mensalmente
        )
        
        for mes in 1...12 {
            let intervalo = intervaloMes(year: 2025, month: mes)
            let total = ocorrencias(in: intervalo).reduce(0) { $0 + $1.amount }
            
            let esperado = 39.90 + 21.90 + 27.90
            
            XCTAssertEqual(total, esperado, accuracy: 0.01, "Mês \(mes)/2025: total esperado \(esperado), obteve \(total)")
        }
    }
    
}
