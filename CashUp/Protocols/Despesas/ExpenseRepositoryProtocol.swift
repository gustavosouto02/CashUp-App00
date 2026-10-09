import Foundation

@MainActor
protocol ExpenseRepositoryProtocol: AnyObject {
    func fetchAll() throws -> [ExpenseModel]
    func fetch(id: UUID) throws -> ExpenseModel?
    func insert(_ expense: ExpenseModel)
    func delete(_ expense: ExpenseModel)
    func save() throws
    func rollback()
}
