//
//  UnitTestLACalucularGastos.swift
//  CashUp
//
//  Created by Andreas Gomes Marchi on 10/03/26.
//

import XCTest
import SwiftUI
@testable import CashUp
import SwiftData


final class UnitTestLACalucularGastos: XCTestCase {
    
    // O teste roda na MainActor pois SwiftData exigi execução na thread principal
    @MainActor func testCalcularTotalGastoParaCategoria() throws {
        
        // Cria uma configuração de banco em memória
        // Isso evita salvar dados reais no disco durante os testes
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        
        // Cria um container do SwiftData contendo os modelos usados no teste
        // Esse container simula o banco de dados do app
        let container = try ModelContainer(
            for: ExpenseModel.self,
            CategoriaModel.self,
            CategoriaPlanejadaModel.self,
            configurations: config
        )
        
        // Cria o contexto que será usado para inserir e buscar dados
        let context = ModelContext(container)
        
        // Cria uma categoria original que será associada às despesas
        let categoria = CategoriaModel(
            nome: "Lanche",
            icon: "knife.icon",
            red: 1.0,
            green: 0.5,
            blue: 0.2
        )

        // Cria uma categoria planejada que referencia a categoria original
        // Essa é a categoria usada na função que queremos testar
        let categoriaPlanejada = CategoriaPlanejadaModel(
            mesAno: Date(),
            categoriaOriginal: categoria
        )

        // Criação de despesas fictícias (mock) para o teste
        
        // Despesa 1 pertence à categoria "Comida"
        let despesa1 = ExpenseModel(
            amount: 50,
            categoria: categoria
        )

        // Despesa 2 também pertence à categoria "Comida"
        let despesa2 = ExpenseModel(
            amount: 30,
            categoria: categoria
        )

        // Despesa 3 não possui categoria
        // Ela serve para garantir que o filtro da função funcione corretamente
        let despesa3 = ExpenseModel(
            amount: 100,
            categoria: nil
        )

        // Cria o ViewModel que contém a função que queremos testar
        let viewModel = ExpensesViewModel(modelContext: context)
        
        // Inserimos os objetos no banco em memória
        // Isso simula dados reais que existiriam no aplicativo
        context.insert(categoria)
        context.insert(despesa1)
        context.insert(despesa2)
        context.insert(despesa3)
        
        // Salva os dados no contexto
        try context.save()

        // Executa a função que queremos testar
        let total = viewModel.calcularTotalGastoParaCategoria(
            categoriaPlanejada,
            paraMes: Date()
        )

        // Verifica se o valor retornado é o esperado
        // Apenas as despesas da categoria "Comida" devem ser somadas (50 + 30)
        XCTAssertEqual(total, 80)
    }
}
