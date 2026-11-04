import Foundation
import SwiftData

/// Remove os `Double` legados e adiciona contas e o tipo de lançamento (despesa, receita ou transferência).
/// As classes ficam em `CashUp/Models/*.swift`.
enum SchemaV5: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(5, 0, 0) }

    static var models: [any PersistentModel.Type] {
        [
            CategoriaModel.self,
            SubcategoriaModel.self,
            ExpenseModel.self,
            CategoriaPlanejadaModel.self,
            SubcategoriaPlanejadaModel.self,
            SeedRemocaoModel.self,
            ContaModel.self,
        ]
    }
}

/// Natureza de um lançamento. Transferência move dinheiro entre contas e não entra em totais de gasto nem de receita (RN-14).
/// Gravado como texto (`ExpenseModel.tipoRaw`) para o schema não depender da ordem dos casos.
enum TipoLancamento: String, Codable, CaseIterable {
    case despesa
    case receita
    case transferencia
}

enum TipoConta: String, Codable, CaseIterable {
    case carteira
    case contaCorrente
    case cartaoCredito
}
