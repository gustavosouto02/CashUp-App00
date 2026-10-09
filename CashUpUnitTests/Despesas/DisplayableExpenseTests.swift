//
//  DisplayableExpenseTests.swift
//  CashUpUnitTests
//
//  Created by Letícia Delmilio Soares on 11/03/26.
//


import XCTest
import SwiftData

@testable import CashUp

final class DisplayableExpenseTests: XCTestCase {

    private let marco = Date.make(year: 2026, month: 3, day: 10)
    
    //MARK: TESTE UNITÁRIO
    // Testes unitários verificam o comportamento de uma classe isoladamente,
    func testNomeCategoriaOriginal() {
        // ARRANGE: cria os objetos necessários para o teste
        let categoria = CategoriaModel(nome: "Doces", icon: "birthday.cake", red: 0.1, green: 0.2, blue: 0.3)
        // ACT: executa a ação que queremos testar
        let categoriaPlanejada = CategoriaPlanejadaModel(
            mesAno: marco,
            categoriaOriginal: categoria
        )
        // ASSERT: verifica se o resultado foi o esperado
        XCTAssertEqual(categoriaPlanejada.nomeCategoriaOriginal, "Doces") //nome da categoria existe
    }
    
    func testCategoriaPlanejadaTemID() {
        // Cria uma categoria planejada e verifica se um ID foi gerado automaticamente
        let categoria = CategoriaPlanejadaModel(mesAno: marco)
        
        XCTAssertNotNil(categoria.id)
    }
    
    func testDisplayableExpenseIsCreated() {
        // Este teste verifica se um DisplayableExpense pode ser criado a partir de um ExpenseModel
        // ARRANGE
        let categoria = CategoriaModel(
            nome: "Comida",
            icon: "fork.knife",
            red: 1.0,
            green: 0.5,
            blue: 0.2
        )
        
        let subcategoria = SubcategoriaModel(nome: "Restaurante")
        
        let expense = ExpenseModel(
            amount: 20,
            date: marco,
            expenseDescription: "Lanche",
            isIncome: false,
            categoria: categoria,
            subcategoria: subcategoria
        )
        
        // ACT
        let displayable = DisplayableExpense(from: expense)
        
        // ASSERT
        XCTAssertNotNil(displayable)
    }
    
    //MARK: Integração
    // Testes de integração verificam se duas ou mais partes do sistema
    // funcionam corretamente quando usadas juntas.
    func testExpenseCategoriaIntegration() { // verifica se dados do ExpenseModel chegam corretamente ao DisplayableExpense
        // ARRANGE
        let categoria = CategoriaModel(
            nome: "Comida",
            icon: "fork.knife",
            red: 1.0,
            green: 0.5,
            blue: 0.2
        )
        
        let subcategoria = SubcategoriaModel(nome: "Restaurante")
        
        let expense = ExpenseModel(
            amount: 15,
            date: marco,
            expenseDescription: "Lanche",
            isIncome: false,
            categoria: categoria,
            subcategoria: subcategoria
        )
        
        // ACT
        let displayable = DisplayableExpense(from: expense)
        
        // ASSERT
        XCTAssertEqual(displayable.date, expense.date) // confirma que a data foi transferida corretamente entre os modelos
    }
    
    
    
    func testExpenseIntegrationWithDisplayableExpense() {
        // Testa se o DisplayableExpense mantém referência ao ID da despesa original
        // ARRANGE
        let categoria = CategoriaModel(
            nome: "Comida",
            icon: "fork.knife",
            red: 1.0,
            green: 0.5,
            blue: 0.2
        )
        
        let subcategoria = SubcategoriaModel(nome: "Restaurante")
        
        let expense = ExpenseModel(
            amount: 30,
            date: marco,
            expenseDescription: "Jantar",
            isIncome: false,
            categoria: categoria,
            subcategoria: subcategoria
        )
        
        // ACT
        let displayable = DisplayableExpense(from: expense, occurrenceDate: marco)
        //    Quando um DisplayableExpense é criado a partir de um ExpenseModel recorrente,
        //    ele deve guardar o ID da despesa original.
        //ASSERT
        XCTAssertEqual(displayable.originalExpenseID, expense.id)
    }
}
