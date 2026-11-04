import SwiftData
import SwiftUI

extension SchemaV5 {
    /// Onde o dinheiro está: carteira, conta corrente ou cartão. Toda transação pertence a uma conta (RN-03).
    @Model
    final class ContaModel {
        var id: UUID = UUID()
        var nome: String = ""
        /// `TipoConta` gravado como texto. Use `tipo`.
        var tipoRaw: String = TipoConta.carteira.rawValue
        var saldoInicialCentavos: Int64 = 0
        /// Posição na lista de contas; a conta padrão é a Carteira (`SeedIDs.idContaCarteira`).
        var ordem: Int = 0

        /// Inversa de `ExpenseModel.conta`: apagar a conta anula a referência nas transações.
        @Relationship(deleteRule: .nullify, inverse: \ExpenseModel.conta)
        var transacoes: [ExpenseModel]? = []

        /// Inversa de `ExpenseModel.contaDestino`: transferências que chegam nesta conta.
        @Relationship(deleteRule: .nullify, inverse: \ExpenseModel.contaDestino)
        var transferenciasRecebidas: [ExpenseModel]? = []

        var instanciaID: UUID = UUID()
        var criadoEm: Date = Date.distantPast
        var atualizadoEm: Date = Date.distantPast

        init(id: UUID = UUID(),
             nome: String,
             tipo: TipoConta = .carteira,
             saldoInicialCentavos: Int64 = 0,
             ordem: Int = 0) {
            self.id = id
            self.nome = nome
            self.tipoRaw = tipo.rawValue
            self.saldoInicialCentavos = saldoInicialCentavos
            self.ordem = ordem
            let agora = Date()
            self.criadoEm = agora
            self.atualizadoEm = agora
        }
    }
}

extension ContaModel {
    static let nomeCarteira = "Carteira"

    var tipo: TipoConta {
        get { TipoConta(rawValue: tipoRaw) ?? .carteira }
        set { tipoRaw = newValue.rawValue }
    }

    /// A Carteira que a migração V4 → V5 e a primeira abertura criam, com ID fixo para o iCloud reconhecer a mesma conta.
    static func carteira() -> ContaModel {
        ContaModel(id: SeedIDs.idContaCarteira, nome: nomeCarteira, tipo: .carteira)
    }
}
