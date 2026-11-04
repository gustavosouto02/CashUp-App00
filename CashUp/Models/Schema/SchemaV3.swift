import Foundation
import SwiftData

enum SchemaV3: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(3, 0, 0) }

    static var models: [any PersistentModel.Type] {
        [
            CategoriaModel.self,
            SubcategoriaModel.self,
            ExpenseModel.self,
            CategoriaPlanejadaModel.self,
            SubcategoriaPlanejadaModel.self,
            SeedRemocaoModel.self,
        ]
    }

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
    }

    @Model
    final class SubcategoriaModel {
        var id: UUID = UUID()
        var nome: String = ""
        var icon: String = ""
        var usageCount: Int = 0
        @Relationship
        var categoria: CategoriaModel?

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

    @Model
    final class ExpenseModel {
        var id: UUID = UUID()
        var amount: Double = 0.0
        var date: Date = Date.distantPast
        var expenseDescription: String = ""
        var isIncome: Bool = false
        @Attribute(.externalStorage)
        var repetition: RepetitionData?

        @Relationship(deleteRule: .nullify)
        var categoria: CategoriaModel?
        @Relationship(deleteRule: .nullify)
        var subcategoria: SubcategoriaModel?

        var instanciaID: UUID = UUID()
        var criadoEm: Date = Date.distantPast
        var atualizadoEm: Date = Date.distantPast

        init(id: UUID = UUID(),
             amount: Double = 0.0,
             date: Date = Date(),
             expenseDescription: String = "",
             isIncome: Bool = false,
             repetition: RepetitionData? = nil,
             categoria: CategoriaModel? = nil,
             subcategoria: SubcategoriaModel? = nil) {
            self.id = id
            self.amount = amount
            self.date = date
            self.expenseDescription = expenseDescription
            self.isIncome = isIncome
            self.repetition = repetition
            self.categoria = categoria
            self.subcategoria = subcategoria
            let agora = Date()
            self.criadoEm = agora
            self.atualizadoEm = agora
        }
    }

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
    }

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
    }

    @Model
    final class SeedRemocaoModel {
        var seedID: UUID = UUID()
        var instanciaID: UUID = UUID()
        var criadoEm: Date = Date.distantPast

        init(seedID: UUID, criadoEm: Date = Date()) {
            self.seedID = seedID
            self.criadoEm = criadoEm
        }
    }
}
