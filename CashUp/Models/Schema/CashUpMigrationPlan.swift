import Foundation
import SwiftData

enum CashUpMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [SchemaV1.self, SchemaV2.self, SchemaV3.self]
    }

    static var stages: [MigrationStage] {
        [migrarV1ParaV2, migrarV2ParaV3]
    }

    static let migrarV1ParaV2 = MigrationStage.lightweight(
        fromVersion: SchemaV1.self,
        toVersion: SchemaV2.self
    )

    /// O default de `instanciaID` vale para o store inteiro: cada registro migrado precisa ganhar o seu antes da deduplicação.
    static let migrarV2ParaV3 = MigrationStage.custom(
        fromVersion: SchemaV2.self,
        toVersion: SchemaV3.self,
        willMigrate: nil,
        didMigrate: { context in
            try renovarInstanciaIDs(em: context)
            try context.save()
        }
    )

    private static func renovarInstanciaIDs(em context: ModelContext) throws {
        try context.fetch(FetchDescriptor<SchemaV3.CategoriaModel>()).forEach { $0.instanciaID = UUID() }
        try context.fetch(FetchDescriptor<SchemaV3.SubcategoriaModel>()).forEach { $0.instanciaID = UUID() }
        try context.fetch(FetchDescriptor<SchemaV3.ExpenseModel>()).forEach { $0.instanciaID = UUID() }
        try context.fetch(FetchDescriptor<SchemaV3.CategoriaPlanejadaModel>()).forEach { $0.instanciaID = UUID() }
        try context.fetch(FetchDescriptor<SchemaV3.SubcategoriaPlanejadaModel>()).forEach { $0.instanciaID = UUID() }
    }
}
