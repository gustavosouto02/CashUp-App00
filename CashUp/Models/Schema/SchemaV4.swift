import Foundation
import SwiftData

/// Dinheiro em centavos (`Int64`). Os `Double` da V3 continuam no schema só para a conversão ler (e zerar);
/// a V5 os remove. As classes ficam em `CashUp/Models/*.swift`.
enum SchemaV4: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(4, 0, 0) }

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
}
