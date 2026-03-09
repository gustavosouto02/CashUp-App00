//
//  SubcategoriaPlanejadaModel.swift
//  CashUp
//
//  Created by Gustavo Souto Pereira on 26/05/25.
//

import SwiftData
import SwiftUI

@Model
final class SubcategoriaPlanejadaModel {
    @Attribute(.unique)
    var id: UUID
    var valorPlanejado: Double
    var subcategoriaOriginal: SubcategoriaModel?
    @Relationship
    var categoriaPlanejada: CategoriaPlanejadaModel?

    init(id: UUID = UUID(),
         valorPlanejado: Double = 0.0,
         subcategoriaOriginal: SubcategoriaModel? = nil,
         categoriaPlanejada: CategoriaPlanejadaModel? = nil) {
        self.id = id
        self.valorPlanejado = valorPlanejado
        self.subcategoriaOriginal = subcategoriaOriginal
        self.categoriaPlanejada = categoriaPlanejada
    }

    var nomeSubcategoriaOriginal: String {
        subcategoriaOriginal?.nome ?? "N/A"
    }
    var iconSubcategoriaOriginal: String {
        subcategoriaOriginal?.icon ?? "questionmark"
    }
    var idSubcategoriaOriginal: UUID? {
        subcategoriaOriginal?.id
    }
}
