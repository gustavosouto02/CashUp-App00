import SwiftData

protocol DeduplicacaoServiceProtocol {
    /// Junta as cópias de um mesmo registro e aplica as lápides do seed num único `save()`. Retorna se algo mudou.
    @discardableResult
    func deduplicar(em context: ModelContext) throws -> Bool
}
