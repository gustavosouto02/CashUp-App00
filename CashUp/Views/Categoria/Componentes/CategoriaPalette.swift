import SwiftUI

struct CategoriaCor: Identifiable, Equatable {
    let id: String
    let nome: String
    let red: Double
    let green: Double
    let blue: Double

    var color: Color {
        Color(red: red, green: green, blue: blue)
    }

    func isSimilar(red otherR: Double, green otherG: Double, blue otherB: Double, tolerance: Double = 0.12) -> Bool {
        abs(red - otherR) < tolerance && abs(green - otherG) < tolerance && abs(blue - otherB) < tolerance
    }
}

enum CategoriaPalette {
    static let coresDisponiveis: [CategoriaCor] = [
        CategoriaCor(id: "carmim", nome: "Vermelho Carmim", red: 0.90, green: 0.14, blue: 0.24),
        CategoriaCor(id: "ambar", nome: "Amarelo Dourado", red: 1.00, green: 0.75, blue: 0.02),
        CategoriaCor(id: "azul_eletrico", nome: "Azul Elétrico", red: 0.05, green: 0.45, blue: 1.00),
        CategoriaCor(id: "violeta", nome: "Roxo Violeta", red: 0.50, green: 0.10, blue: 0.95),
        CategoriaCor(id: "lima", nome: "Verde Lima", red: 0.40, green: 0.85, blue: 0.05),
        CategoriaCor(id: "ciano", nome: "Ciano Celeste", red: 0.00, green: 0.72, blue: 0.88),
        CategoriaCor(id: "magenta", nome: "Magenta Pink", red: 0.85, green: 0.10, blue: 0.65),
        CategoriaCor(id: "grafite", nome: "Cinza Ardósia", red: 0.45, green: 0.50, blue: 0.58)
    ]

    static func estaEmUso(cor: CategoriaCor, em categorias: [CategoriaModel], ignorandoCategoriaID: UUID? = nil) -> Bool {
        categorias.contains { cat in
            guard cat.id != ignorandoCategoriaID else { return false }
            return cor.isSimilar(red: cat.redComponent, green: cat.greenComponent, blue: cat.blueComponent)
        }
    }

    static func primeiraDisponivel(em categorias: [CategoriaModel]) -> CategoriaCor {
        coresDisponiveis.first(where: { !estaEmUso(cor: $0, em: categorias) }) ?? coresDisponiveis[0]
    }
}
