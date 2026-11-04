import Foundation
import SwiftData

@testable import CashUp

/// Store como o `main` (App Store 1.5) criava: schema sem versão, só com a lista de modelos da `SchemaV1`.
/// Compartilhada pelos testes de migração de schema e de mudança de local do store.
enum FixtureStoreV1 {
    static let idCategoria = UUID()
    static let idSubcategoria = UUID()
    static let idRecorrente = UUID()
    static let idReceita = UUID()
    static let idPlanejada = UUID()
    static let marco = Date.make(year: 2026, month: 3, day: 10)
    static let excluida = Date.make(year: 2026, month: 5, day: 10)

    /// Duas transações (R$ 49,90 recorrente e R$ 1.800,00 de receita = 184.990 centavos), uma categoria, uma subcategoria
    /// e um planejamento de R$ 300,00.
    static let totalEmCentavos: Int64 = 184_990

    static func criar(em url: URL) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let schema = Schema(SchemaV1.models)
        let container = try ModelContainer(for: schema, configurations: ModelConfiguration(schema: schema, url: url))
        let contexto = ModelContext(container)

        let categoria = SchemaV1.CategoriaModel(id: idCategoria, nome: "Transporte", icon: "car", red: 0.75, green: 0.35, blue: 0.98)
        let subcategoria = SchemaV1.SubcategoriaModel(id: idSubcategoria, nome: "Ônibus", icon: "bus", categoria: categoria, usageCount: 3)
        contexto.insert(categoria)
        contexto.insert(subcategoria)

        contexto.insert(SchemaV1.ExpenseModel(
            id: idRecorrente,
            amount: 49.9,
            date: marco,
            expenseDescription: "Passe",
            repetition: RepetitionData(repeatOption: .mensalmente, endDate: nil, excludedDates: [excluida]),
            categoria: categoria,
            subcategoria: subcategoria
        ))
        contexto.insert(SchemaV1.ExpenseModel(
            id: idReceita,
            amount: 1800,
            date: marco,
            expenseDescription: "Bolsa",
            isIncome: true,
            categoria: categoria,
            subcategoria: subcategoria
        ))

        let planejada = SchemaV1.CategoriaPlanejadaModel(id: idPlanejada, mesAno: marco, categoriaOriginal: categoria)
        contexto.insert(planejada)
        contexto.insert(SchemaV1.SubcategoriaPlanejadaModel(valorPlanejado: 300, subcategoriaOriginal: subcategoria, categoriaPlanejada: planejada))

        try contexto.save()
    }
}
