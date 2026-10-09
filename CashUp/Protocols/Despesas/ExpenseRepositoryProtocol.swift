import Foundation

@MainActor
protocol ExpenseRepositoryProtocol: AnyObject {
    func fetchAll() throws -> [ExpenseModel]
    func fetch(id: UUID) throws -> ExpenseModel?
    func insert(_ expense: ExpenseModel) throws
    func delete(_ expense: ExpenseModel) throws
    func save() throws
}
