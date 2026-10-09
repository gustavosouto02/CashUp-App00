import Foundation
import SwiftData

@MainActor
final class SwiftDataExpenseRepository: ExpenseRepositoryProtocol {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchAll() throws -> [ExpenseModel] {
        let descriptor = FetchDescriptor<ExpenseModel>()
        return try context.fetch(descriptor)
    }

    func fetch(id: UUID) throws -> ExpenseModel? {
        let predicate = #Predicate<ExpenseModel> { $0.id == id }
        var descriptor = FetchDescriptor(predicate: predicate)
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    func insert(_ expense: ExpenseModel) {
        context.insert(expense)
    }

    func delete(_ expense: ExpenseModel) {
        context.delete(expense)
    }

    func save() throws {
        try context.save()
    }

    func rollback() {
        context.rollback()
    }
}
