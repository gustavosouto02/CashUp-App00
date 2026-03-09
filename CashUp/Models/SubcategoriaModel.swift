//
//  SubcategoriaModel.swift
//  CashUp
//
//  Created by Gustavo Souto Pereira on 26/05/25.
//

import SwiftData
import SwiftUI

@Model
final class SubcategoriaModel {
    @Attribute(.unique)
    var id: UUID
    
    var nome: String
    var icon: String
    var usageCount: Int = 0
    @Relationship
    var categoria: CategoriaModel?
    
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
    }
}
