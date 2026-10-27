//
//  CategoriaPlanejadaModel.swift
//  CashUp
//
//  Created by Gustavo Souto Pereira on 26/05/25.
//

import SwiftData
import SwiftUI

extension SchemaV2 {
    @Model
    final class CategoriaPlanejadaModel {
        @Attribute(.unique)
        var id: UUID
        var mesAno: Date

        var categoriaOriginal: CategoriaModel?

        @Relationship(deleteRule: .cascade, inverse: \SubcategoriaPlanejadaModel.categoriaPlanejada)
        var subcategoriasPlanejadas: [SubcategoriaPlanejadaModel]? = []

        init(id: UUID = UUID(),
             mesAno: Date,
             categoriaOriginal: CategoriaModel? = nil,
             subcategoriasPlanejadas: [SubcategoriaPlanejadaModel]? = []) {
            self.id = id
            self.mesAno = mesAno.startOfMonth()
            self.categoriaOriginal = categoriaOriginal
            self.subcategoriasPlanejadas = subcategoriasPlanejadas
        }

        var nomeCategoriaOriginal: String {
            categoriaOriginal?.nome ?? "N/A"
        }
        var corCategoriaOriginal: Color {
            categoriaOriginal?.color ?? .gray
        }
        var iconCategoriaOriginal: String {
            categoriaOriginal?.icon ?? "questionmark"
        }
        var idCategoriaOriginal: UUID? {
            categoriaOriginal?.id
        }
    }
}

extension CategoriaPlanejadaModel {
    var valorTotalPlanejado: Double {
        subcategoriasPlanejadas?.reduce(0) { $0 + $1.valorPlanejado } ?? 0
    }
}

