import Foundation
import SwiftData

extension SchemaV3 {
    /// Lápide de um item do seed apagado pelo usuário: impede que o seed o recrie e avisa os outros aparelhos.
    @Model
    final class SeedRemocaoModel {
        var seedID: UUID = UUID()
        var instanciaID: UUID = UUID()
        var criadoEm: Date = Date.distantPast

        init(seedID: UUID, criadoEm: Date = Date()) {
            self.seedID = seedID
            self.criadoEm = criadoEm
        }
    }
}
