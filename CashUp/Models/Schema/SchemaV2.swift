import Foundation
import SwiftData

enum SchemaV2: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(2, 0, 0) }

    static var models: [any PersistentModel.Type] {
        [
            CategoriaModel.self,
            SubcategoriaModel.self,
            ExpenseModel.self,
            CategoriaPlanejadaModel.self,
            SubcategoriaPlanejadaModel.self,
        ]
    }

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

        @Relationship(deleteRule: .nullify, inverse: \ExpenseModel.categoria)
        var transacoes: [ExpenseModel] = []

        init(id: UUID = UUID(), nome: String, icon: String, red: Double, green: Double, blue: Double) {
            self.id = id
            self.nome = nome
            self.icon = icon
            self.redComponent = red
            self.greenComponent = green
            self.blueComponent = blue
        }
    }

    @Model
    final class SubcategoriaModel {
        @Attribute(.unique)
        var id: UUID
        var nome: String
        var icon: String
        var usageCount: Int = 0
        @Relationship
        var categoria: CategoriaModel?

        @Relationship(deleteRule: .nullify, inverse: \ExpenseModel.subcategoria)
        var transacoes: [ExpenseModel] = []

        init(id: UUID = UUID(), nome: String = "", icon: String = "", categoria: CategoriaModel? = nil, usageCount: Int = 0) {
            self.id = id
            self.nome = nome
            self.icon = icon
            self.categoria = categoria
            self.usageCount = usageCount
        }
    }

    @Model
    final class ExpenseModel {
        @Attribute(.unique)
        var id: UUID
        var amount: Double
        var date: Date
        var expenseDescription: String
        var isIncome: Bool
        @Attribute(.externalStorage)
        var repetition: RepetitionData?

        @Relationship(deleteRule: .nullify)
        var categoria: CategoriaModel?
        @Relationship(deleteRule: .nullify)
        var subcategoria: SubcategoriaModel?

        init(
            id: UUID = UUID(),
            amount: Double = 0.0,
            date: Date = Date(),
            expenseDescription: String = "",
            isIncome: Bool = false,
            repetition: RepetitionData? = nil,
            categoria: CategoriaModel? = nil,
            subcategoria: SubcategoriaModel? = nil
        ) {
            self.id = id
            self.amount = amount
            self.date = date
            self.expenseDescription = expenseDescription
            self.isIncome = isIncome
            self.repetition = repetition
            self.categoria = categoria
            self.subcategoria = subcategoria
        }
    }

    @Model
    final class CategoriaPlanejadaModel {
        @Attribute(.unique)
        var id: UUID
        var mesAno: Date

        var categoriaOriginal: CategoriaModel?

        @Relationship(deleteRule: .cascade, inverse: \SubcategoriaPlanejadaModel.categoriaPlanejada)
        var subcategoriasPlanejadas: [SubcategoriaPlanejadaModel]? = []

        init(id: UUID = UUID(), mesAno: Date, categoriaOriginal: CategoriaModel? = nil) {
            self.id = id
            self.mesAno = mesAno.startOfMonth()
            self.categoriaOriginal = categoriaOriginal
        }
    }

    @Model
    final class SubcategoriaPlanejadaModel {
        @Attribute(.unique)
        var id: UUID
        var valorPlanejado: Double
        var subcategoriaOriginal: SubcategoriaModel?
        @Relationship
        var categoriaPlanejada: CategoriaPlanejadaModel?

        init(
            id: UUID = UUID(),
            valorPlanejado: Double = 0.0,
            subcategoriaOriginal: SubcategoriaModel? = nil,
            categoriaPlanejada: CategoriaPlanejadaModel? = nil
        ) {
            self.id = id
            self.valorPlanejado = valorPlanejado
            self.subcategoriaOriginal = subcategoriaOriginal
            self.categoriaPlanejada = categoriaPlanejada
        }
    }
}
