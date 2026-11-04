import Foundation
import SwiftData

@MainActor
final class SwiftDataContaRepository: ContaRepositoryProtocol {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchContas() throws -> [ContaModel] {
        try context.fetch(FetchDescriptor<ContaModel>()).sorted(by: Self.ordemDeExibicao)
    }

    func fetchConta(id: UUID) throws -> ContaModel? {
        let predicate = #Predicate<ContaModel> { $0.id == id }
        var descriptor = FetchDescriptor(predicate: predicate)
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    func contaPadrao() throws -> ContaModel {
        if let carteira = try fetchConta(id: SeedIDs.idContaCarteira) { return carteira }
        if let primeira = try fetchContas().first { return primeira }
        let carteira = ContaModel.carteira()
        context.insert(carteira)
        return carteira
    }

    func insert(_ conta: ContaModel) {
        context.insert(conta)
    }

    func delete(_ conta: ContaModel) {
        context.delete(conta)
    }

    func save() throws {
        try context.save()
    }

    func rollback() {
        context.rollback()
    }

    /// Por `ordem`; no empate, a mais antiga e depois o `instanciaID`, para todos os aparelhos listarem na mesma ordem.
    private static func ordemDeExibicao(_ a: ContaModel, _ b: ContaModel) -> Bool {
        if a.ordem != b.ordem { return a.ordem < b.ordem }
        if a.criadoEm != b.criadoEm { return a.criadoEm < b.criadoEm }
        return a.instanciaID.uuidString < b.instanciaID.uuidString
    }
}
