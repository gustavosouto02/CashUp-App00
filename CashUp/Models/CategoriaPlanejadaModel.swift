//
//  CategoriaPlanejadaModel.swift
//  CashUp
//
//  Created by Gustavo Souto Pereira on 26/05/25.
//

import SwiftData
import SwiftUI

extension SchemaV3 {
    @Model
    final class CategoriaPlanejadaModel {
        var id: UUID = UUID()
        var mesAno: Date = Date.distantPast

        var categoriaOriginal: CategoriaModel?

        @Relationship(deleteRule: .cascade, inverse: \SubcategoriaPlanejadaModel.categoriaPlanejada)
        var subcategoriasPlanejadas: [SubcategoriaPlanejadaModel]? = []

        var instanciaID: UUID = UUID()
        var criadoEm: Date = Date.distantPast
        var atualizadoEm: Date = Date.distantPast

        init(id: UUID = UUID(),
             mesAno: Date,
             categoriaOriginal: CategoriaModel? = nil,
             subcategoriasPlanejadas: [SubcategoriaPlanejadaModel]? = []) {
            self.id = id
            self.mesAno = mesAno.startOfMonth()
            self.categoriaOriginal = categoriaOriginal
            self.subcategoriasPlanejadas = subcategoriasPlanejadas
            let agora = Date()
            self.criadoEm = agora
            self.atualizadoEm = agora
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

