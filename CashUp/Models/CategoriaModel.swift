//
//  CategoriaModel.swift
//  CashUp
//
//  Created by Gustavo Souto Pereira on 26/05/25.
//

import SwiftData
import SwiftUI

extension SchemaV3 {
    @Model
    final class CategoriaModel {
        var id: UUID = UUID()
        var nome: String = ""
        var icon: String = ""
        var redComponent: Double = 0
        var greenComponent: Double = 0
        var blueComponent: Double = 0

        @Relationship(deleteRule: .cascade, inverse: \SubcategoriaModel.categoria)
        var subcategorias: [SubcategoriaModel]? = []

        /// Inversa de `ExpenseModel.categoria`: apagar a categoria anula a referência nas transações.
        @Relationship(deleteRule: .nullify, inverse: \ExpenseModel.categoria)
        var transacoes: [ExpenseModel]? = []

        var instanciaID: UUID = UUID()
        var criadoEm: Date = Date.distantPast
        var atualizadoEm: Date = Date.distantPast

        init(id: UUID = UUID(),
             nome: String,
             icon: String,
             red: Double,
             green: Double,
             blue: Double,
             subcategorias: [SubcategoriaModel]? = []) {

            self.id = id
            self.nome = nome
            self.icon = icon
            self.redComponent = red
            self.greenComponent = green
            self.blueComponent = blue
            self.subcategorias = subcategorias ?? []
            let agora = Date()
            self.criadoEm = agora
            self.atualizadoEm = agora
        }


        var color: Color {
            Color(red: redComponent, green: greenComponent, blue: blueComponent)
        }

    }
}
