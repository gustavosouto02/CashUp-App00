//
//  CategoriaModel.swift
//  CashUp
//
//  Created by Gustavo Souto Pereira on 26/05/25.
//

import SwiftData
import SwiftUI

@Model
final class CategoriaModel {
    @Attribute(.unique)
    var id: UUID
    var nome: String
    var icon: String
    var redComponent: Double
    var greenComponent: Double
    var blueComponent: Double
    
    @Relationship(deleteRule: .cascade, inverse: \SubcategoriaModel.categoria)
    var subcategorias: [SubcategoriaModel] = []

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
    }


    var color: Color {
        Color(red: redComponent, green: greenComponent, blue: blueComponent)
    }

}
