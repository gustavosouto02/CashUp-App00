import Foundation
import SwiftData

enum CashUpMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [SchemaV1.self, SchemaV2.self, SchemaV3.self, SchemaV4.self, SchemaV5.self]
    }

    static var stages: [MigrationStage] {
        [migrarV1ParaV2, migrarV2ParaV3, migrarV3ParaV4, migrarV4ParaV5]
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

    /// Remove os `Double` legados e cria as contas. O `willMigrate` ainda enxerga a V4 e termina a conversão para centavos
    /// (inclusive de um store que ficou V4 com centavos zerados por uma falha no estágio V3 → V4), porque depois deste
    /// estágio o `Double` deixa de existir. O `didMigrate` cria a Carteira e liga todas as transações a ela.
    static let migrarV4ParaV5 = MigrationStage.custom(
        fromVersion: SchemaV4.self,
        toVersion: SchemaV5.self,
        willMigrate: { context in
            try converterValoresPendentesParaCentavos(em: context)
            try context.save()
        },
        didMigrate: { context in
            try garantirCarteira(em: context)
            try vincularTransacoesPendentesAContaPadrao(em: context)
            try context.save()
        }
    )

    /// Converte para centavos todo registro que ainda tem valor no `Double` legado e zera o legado em seguida
    /// (o legado zerado é a marca de "já convertido"). Idempotente; roda no `willMigrate` do estágio V4 → V5, com as
    /// classes congeladas da V4. Edições feitas na V4 nunca tocam o `Double` legado, então um valor editado para zero
    /// não é ressuscitado.
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

    /// Garante a Carteira (ID fixo) e a devolve. Idempotente: uma segunda chamada, ou um estágio repetido, reaproveita a conta.
    @discardableResult
    static func garantirCarteira(em context: ModelContext) throws -> SchemaV5.ContaModel {
        let id = SeedIDs.idContaCarteira
        var descriptor = FetchDescriptor<SchemaV5.ContaModel>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        if let existente = try context.fetch(descriptor).first { return existente }
        let carteira = SchemaV5.ContaModel(id: id, nome: ContaModel.nomeCarteira, tipo: .carteira)
        context.insert(carteira)
        return carteira
    }

    /// Liga à Carteira toda transação sem conta e define o tipo a partir de `isIncome` (uma transferência mantém o tipo).
    /// Idempotente: só toca o que ainda não tem conta. Roda no `didMigrate` do estágio V4 → V5 e na abertura do container
    /// (`CashUpPersistence`); o segundo cobre o `didMigrate` que falha, quando o SwiftData já aplicou a mudança estrutural
    /// e o store é V5 com transações sem conta e com o tipo no valor padrão (despesa), então as receitas somariam como despesa.
    /// Sai da abertura do container quando existir uma V6 (o estágio V5 → V6 passa a chamá-la no `willMigrate`).
    @discardableResult
    static func vincularTransacoesPendentesAContaPadrao(em context: ModelContext) throws -> Int {
        let pendentes = try context.fetch(FetchDescriptor<SchemaV5.ExpenseModel>(predicate: #Predicate { $0.conta == nil }))
        guard !pendentes.isEmpty else { return 0 }
        let carteira = try garantirCarteira(em: context)
        for transacao in pendentes {
            transacao.conta = carteira
            if transacao.tipo != .transferencia {
                transacao.tipo = transacao.isIncome ? .receita : .despesa
            }
        }
        return pendentes.count
    }

    private static func renovarInstanciaIDs(em context: ModelContext) throws {
        try context.fetch(FetchDescriptor<SchemaV3.CategoriaModel>()).forEach { $0.instanciaID = UUID() }
        try context.fetch(FetchDescriptor<SchemaV3.SubcategoriaModel>()).forEach { $0.instanciaID = UUID() }
        try context.fetch(FetchDescriptor<SchemaV3.ExpenseModel>()).forEach { $0.instanciaID = UUID() }
        try context.fetch(FetchDescriptor<SchemaV3.CategoriaPlanejadaModel>()).forEach { $0.instanciaID = UUID() }
        try context.fetch(FetchDescriptor<SchemaV3.SubcategoriaPlanejadaModel>()).forEach { $0.instanciaID = UUID() }
    }
}
