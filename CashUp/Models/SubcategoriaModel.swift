//
//  SubcategoriaModel.swift
//  CashUp
//
//  Created by Gustavo Souto Pereira on 26/05/25.
//

import SwiftData
import SwiftUI

extension SchemaV3 {
    @Model
    final class SubcategoriaModel {
        var id: UUID = UUID()
        var nome: String = ""
        var icon: String = ""
        var usageCount: Int = 0
        @Relationship
        var categoria: CategoriaModel?

        /// Inversa de `ExpenseModel.subcategoria`: apagar a subcategoria anula a referência nas transações.
        @Relationship(deleteRule: .nullify, inverse: \ExpenseModel.subcategoria)
        var transacoes: [ExpenseModel]? = []

        var instanciaID: UUID = UUID()
        var criadoEm: Date = Date.distantPast
        var atualizadoEm: Date = Date.distantPast
    
        init(id: UUID = UUID(),
             nome: String = "",
             icon: String = "",
             categoria: CategoriaModel? = nil,
             usageCount: Int = 0) {
        
            self.id = id
            self.nome = nome
            self.icon = icon
            self.categoria = categoria
            self.usageCount = usageCount
            let agora = Date()
            self.criadoEm = agora
            self.atualizadoEm = agora
        }
    }
}
