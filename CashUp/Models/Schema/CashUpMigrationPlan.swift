import Foundation
import SwiftData

enum CashUpMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [SchemaV1.self, SchemaV2.self, SchemaV3.self, SchemaV4.self]
    }

    static var stages: [MigrationStage] {
        [migrarV1ParaV2, migrarV2ParaV3, migrarV3ParaV4]
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

    /// Os campos em centavos nascem zerados: `didMigrate` converte o `Double` legado de cada registro.
    static let migrarV3ParaV4 = MigrationStage.custom(
        fromVersion: SchemaV3.self,
        toVersion: SchemaV4.self,
        willMigrate: nil,
        didMigrate: { context in
            try converterValoresPendentesParaCentavos(em: context)
            try context.save()
        }
    )

    /// Converte para centavos todo registro que ainda tem valor no `Double` legado e zera o legado em seguida
    /// (o legado zerado é a marca de "já convertido"). É idempotente e roda em dois lugares:
    /// no `didMigrate` do estágio V3 → V4 e na abertura do container (`CashUpPersistence`). O segundo cobre o caso
    /// em que o `didMigrate` falha: o SwiftData já aplicou a mudança estrutural, o store passa a ser V4 com os
    /// centavos zerados, e a próxima abertura não repetiria o estágio. Sem o reparo, os totais apareceriam zerados.
    /// Edições feitas na V4 nunca tocam o `Double` legado, então um valor editado para zero não é ressuscitado.
    /// Sai junto com os campos legados, na E0.4 (V5).
    @discardableResult
    static func converterValoresPendentesParaCentavos(em context: ModelContext) throws -> Int {
        let despesas = try context.fetch(FetchDescriptor<SchemaV4.ExpenseModel>(predicate: #Predicate { $0.amount != 0 }))
        for despesa in despesas {
            despesa.amountInCents = Centavos.de(reais: despesa.amount)
            despesa.amount = 0
        }
        let planejadas = try context.fetch(FetchDescriptor<SchemaV4.SubcategoriaPlanejadaModel>(predicate: #Predicate { $0.valorPlanejado != 0 }))
        for planejada in planejadas {
            planejada.valorPlanejadoCentavos = Centavos.de(reais: planejada.valorPlanejado)
            planejada.valorPlanejado = 0
        }
        return despesas.count + planejadas.count
    }

    private static func renovarInstanciaIDs(em context: ModelContext) throws {
        try context.fetch(FetchDescriptor<SchemaV3.CategoriaModel>()).forEach { $0.instanciaID = UUID() }
        try context.fetch(FetchDescriptor<SchemaV3.SubcategoriaModel>()).forEach { $0.instanciaID = UUID() }
        try context.fetch(FetchDescriptor<SchemaV3.ExpenseModel>()).forEach { $0.instanciaID = UUID() }
        try context.fetch(FetchDescriptor<SchemaV3.CategoriaPlanejadaModel>()).forEach { $0.instanciaID = UUID() }
        try context.fetch(FetchDescriptor<SchemaV3.SubcategoriaPlanejadaModel>()).forEach { $0.instanciaID = UUID() }
    }
}
