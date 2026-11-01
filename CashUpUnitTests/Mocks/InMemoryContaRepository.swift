import Foundation
@testable import CashUp

@MainActor
final class InMemoryContaRepository: ContaRepositoryProtocol {
    var contas: [ContaModel] = []
    var shouldFailSave: Bool = false
    var shouldFailFetch: Bool = false
    var saveCallCount: Int = 0
    var rollbackCallCount: Int = 0

    init(contas: [ContaModel] = []) {
        self.contas = contas
    }

    func fetchContas() throws -> [ContaModel] {
        if shouldFailFetch { throw CashUpDomainError.persistencia("Falha forçada no fetch") }
        return contas.sorted { $0.ordem < $1.ordem }
    }

    func fetchConta(id: UUID) throws -> ContaModel? {
        if shouldFailFetch { throw CashUpDomainError.persistencia("Falha forçada no fetch") }
        return contas.first { $0.id == id }
    }

    func contaPadrao() throws -> ContaModel {
        if shouldFailFetch { throw CashUpDomainError.persistencia("Falha forçada no fetch") }
        if let carteira = contas.first(where: { $0.id == SeedIDs.idContaCarteira }) { return carteira }
        if let primeira = try fetchContas().first { return primeira }
        let carteira = ContaModel.carteira()
        contas.append(carteira)
        return carteira
    }

    func insert(_ conta: ContaModel) {
        contas.append(conta)
    }

    func delete(_ conta: ContaModel) {
        contas.removeAll { $0.id == conta.id }
    }

    func save() throws {
        saveCallCount += 1
        if shouldFailSave {
            throw CashUpDomainError.persistencia("Falha forçada no save")
        }
    }

    func rollback() {
        rollbackCallCount += 1
    }
}
