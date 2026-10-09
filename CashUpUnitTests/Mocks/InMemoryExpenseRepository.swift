import Foundation
@testable import CashUp

@MainActor
final class InMemoryExpenseRepository: ExpenseRepositoryProtocol {
    var expenses: [ExpenseModel] = []
    var shouldFailSave: Bool = false
    var saveCallCount: Int = 0
    var rollbackCallCount: Int = 0

    init(expenses: [ExpenseModel] = []) {
        self.expenses = expenses
    }

    func fetchAll() throws -> [ExpenseModel] {
        expenses
    }

    func fetch(id: UUID) throws -> ExpenseModel? {
        expenses.first { $0.id == id }
    }

    func insert(_ expense: ExpenseModel) {
        expenses.append(expense)
    }

    func delete(_ expense: ExpenseModel) {
        expenses.removeAll { $0.id == expense.id }
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
