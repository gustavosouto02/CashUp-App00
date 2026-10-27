import Foundation
import SwiftData

enum CashUpPersistence {
    static let schema = Schema(versionedSchema: SchemaAtual.self)

    static func makeContainer(inMemory: Bool) throws -> ModelContainer {
        try makeContainer(configuration: ModelConfiguration(schema: schema, isStoredInMemoryOnly: inMemory))
    }

    static func makeContainer(url: URL) throws -> ModelContainer {
        try makeContainer(configuration: ModelConfiguration(schema: schema, url: url))
    }

    private static func makeContainer(configuration: ModelConfiguration) throws -> ModelContainer {
        try ModelContainer(for: schema, migrationPlan: CashUpMigrationPlan.self, configurations: configuration)
    }
}
