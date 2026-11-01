import Foundation

@MainActor
protocol ContaRepositoryProtocol: AnyObject {
    func fetchContas() throws -> [ContaModel]
    func fetchConta(id: UUID) throws -> ContaModel?
    /// Conta onde os lançamentos novos caem: a Carteira, ou a primeira conta se ela não existir mais.
    /// Cria (sem salvar) a Carteira quando o store não tem nenhuma conta, como na primeira abertura.
    func contaPadrao() throws -> ContaModel
    func insert(_ conta: ContaModel)
    func delete(_ conta: ContaModel)
    func save() throws
    func rollback()
}
