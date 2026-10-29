//
//  SubcategoriaPlanejadaModel.swift
//  CashUp
//
//  Created by Gustavo Souto Pereira on 26/05/25.
//

import SwiftData
import SwiftUI

extension SchemaV3 {
    @Model
    final class SubcategoriaPlanejadaModel {
        var id: UUID = UUID()
        var valorPlanejado: Double = 0.0
        var subcategoriaOriginal: SubcategoriaModel?
        @Relationship
        var categoriaPlanejada: CategoriaPlanejadaModel?

        var instanciaID: UUID = UUID()
        var criadoEm: Date = Date.distantPast
        var atualizadoEm: Date = Date.distantPast

        init(id: UUID = UUID(),
             valorPlanejado: Double = 0.0,
             subcategoriaOriginal: SubcategoriaModel? = nil,
             categoriaPlanejada: CategoriaPlanejadaModel? = nil) {
            self.id = id
            self.valorPlanejado = valorPlanejado
            self.subcategoriaOriginal = subcategoriaOriginal
            self.categoriaPlanejada = categoriaPlanejada
            let agora = Date()
            self.criadoEm = agora
            self.atualizadoEm = agora
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
}
