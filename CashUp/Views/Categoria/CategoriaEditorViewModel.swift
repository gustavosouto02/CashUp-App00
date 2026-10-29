import Foundation
import SwiftUI

@MainActor
final class CategoriaEditorViewModel: ObservableObject {
    @Published var categorias: [CategoriaModel] = []
    @Published var errorMessage: String?
    @Published var isProcessing: Bool = false

    private let repository: CategoriaRepositoryProtocol

    init(repository: CategoriaRepositoryProtocol) {
        self.repository = repository
        carregar()
    }

    func carregar() {
        do {
            categorias = try repository.fetchCategorias(filtro: nil)
        } catch {
            errorMessage = error.localizedDescription
            CashUpLogger.persistence.error("Erro ao carregar categorias: \(error.localizedDescription, privacy: .public)")
        }
    }

    func criarCategoria(nome: String, cor: CategoriaCor, icone: String) throws -> CategoriaModel {
        let nomeTrim = nome.trimmingCharacters(in: .whitespacesAndNewlines)
        try validarNome(nomeTrim)

        if categorias.contains(where: { $0.nome.localizedCaseInsensitiveCompare(nomeTrim) == .orderedSame }) {
            throw CashUpDomainError.nomeDuplicado(nomeTrim)
        }

        if CategoriaPalette.estaEmUso(cor: cor, em: categorias) {
            throw CashUpDomainError.corEmUso
        }

        let novaCategoria = CategoriaModel(
            id: UUID(),
            nome: nomeTrim,
            icon: icone,
            red: cor.red,
            green: cor.green,
            blue: cor.blue
        )

        let subPadrao = SubcategoriaModel(
            id: UUID(),
            nome: "Diversos",
            icon: "archivebox.fill",
            categoria: novaCategoria
        )
        novaCategoria.subcategorias = [subPadrao]

        repository.insert(novaCategoria)
        repository.insert(subPadrao)

        do {
            try repository.save()
            carregar()
            return novaCategoria
        } catch {
            repository.rollback()
            throw error
        }
    }

    func editarCategoria(_ categoria: CategoriaModel, novoNome: String, novaCor: CategoriaCor, novoIcone: String) throws {
        if categoria.id == SeedIDs.idRenda {
            throw CashUpDomainError.categoriaProtegida
        }

        let nomeTrim = novoNome.trimmingCharacters(in: .whitespacesAndNewlines)
        try validarNome(nomeTrim)

        if categorias.contains(where: { $0.id != categoria.id && $0.nome.localizedCaseInsensitiveCompare(nomeTrim) == .orderedSame }) {
            throw CashUpDomainError.nomeDuplicado(nomeTrim)
        }

        if SeedIDs.isCategoriaBase(id: categoria.id) {
            let corOriginal = CategoriaCor(
                id: "base",
                nome: "Base",
                red: categoria.redComponent,
                green: categoria.greenComponent,
                blue: categoria.blueComponent
            )
            if !corOriginal.isSimilar(red: novaCor.red, green: novaCor.green, blue: novaCor.blue, tolerance: 0.02) {
                throw CashUpDomainError.corCategoriaBaseProtegida
            }
        } else {
            if CategoriaPalette.estaEmUso(cor: novaCor, em: categorias, ignorandoCategoriaID: categoria.id) {
                throw CashUpDomainError.corEmUso
            }
            categoria.redComponent = novaCor.red
            categoria.greenComponent = novaCor.green
            categoria.blueComponent = novaCor.blue
        }

        categoria.nome = nomeTrim
        categoria.icon = novoIcone
        categoria.atualizadoEm = Date()

        do {
            try repository.save()
            carregar()
        } catch {
            repository.rollback()
            throw error
        }
    }

    func apagarCategoria(_ categoria: CategoriaModel) throws {
        if categoria.id == SeedIDs.idRenda {
            throw CashUpDomainError.categoriaProtegida
        }

        let transacoes = categoria.transacoes ?? []
        if !transacoes.isEmpty {
            throw CashUpDomainError.categoriaEmUso(quantidadeTransacoes: transacoes.count)
        }

        registrarRemocaoSeSeed(id: categoria.id)
        repository.delete(categoria)

        do {
            try repository.save()
            carregar()
        } catch {
            repository.rollback()
            throw error
        }
    }

    func criarSubcategoria(em categoria: CategoriaModel, nome: String, icone: String) throws -> SubcategoriaModel {
        let nomeTrim = nome.trimmingCharacters(in: .whitespacesAndNewlines)
        try validarNome(nomeTrim)

        if (categoria.subcategorias ?? []).contains(where: { $0.nome.localizedCaseInsensitiveCompare(nomeTrim) == .orderedSame }) {
            throw CashUpDomainError.nomeDuplicado(nomeTrim)
        }

        let novaSub = SubcategoriaModel(
            id: UUID(),
            nome: nomeTrim,
            icon: icone,
            categoria: categoria
        )

        categoria.subcategorias = (categoria.subcategorias ?? []) + [novaSub]
        repository.insert(novaSub)

        do {
            try repository.save()
            carregar()
            return novaSub
        } catch {
            repository.rollback()
            throw error
        }
    }

    func editarSubcategoria(_ subcategoria: SubcategoriaModel, novoNome: String, novoIcone: String) throws {
        let nomeTrim = novoNome.trimmingCharacters(in: .whitespacesAndNewlines)
        try validarNome(nomeTrim)

        if let pai = subcategoria.categoria {
            if (pai.subcategorias ?? []).contains(where: { $0.id != subcategoria.id && $0.nome.localizedCaseInsensitiveCompare(nomeTrim) == .orderedSame }) {
                throw CashUpDomainError.nomeDuplicado(nomeTrim)
            }
        }

        subcategoria.nome = nomeTrim
        subcategoria.icon = novoIcone
        subcategoria.atualizadoEm = Date()

        do {
            try repository.save()
            carregar()
        } catch {
            repository.rollback()
            throw error
        }
    }

    func apagarSubcategoria(_ subcategoria: SubcategoriaModel) throws {
        guard let categoriaPai = subcategoria.categoria else {
            registrarRemocaoSeSeed(id: subcategoria.id)
            repository.delete(subcategoria)
            try repository.save()
            carregar()
            return
        }

        let irmas = categoriaPai.subcategorias ?? []
        if categoriaPai.id == SeedIDs.idRenda && irmas.count <= 1 {
            throw CashUpDomainError.subcategoriaProtegida
        }

        let transacoes = subcategoria.transacoes ?? []
        if !transacoes.isEmpty {
            let destino = irmas.first(where: {
                $0.id != subcategoria.id && $0.nome.localizedCaseInsensitiveCompare("Diversos") == .orderedSame
            }) ?? irmas.first(where: { $0.id != subcategoria.id })

            guard let destinoFinal = destino else {
                throw CashUpDomainError.subcategoriaEmUso(quantidadeTransacoes: transacoes.count)
            }

            for transacao in transacoes {
                transacao.subcategoria = destinoFinal
            }
        }

        categoriaPai.subcategorias?.removeAll { $0.id == subcategoria.id }
        registrarRemocaoSeSeed(id: subcategoria.id)
        repository.delete(subcategoria)

        do {
            try repository.save()
            carregar()
        } catch {
            repository.rollback()
            throw error
        }
    }

    private func registrarRemocaoSeSeed(id: UUID) {
        guard SeedCatalogo.todosIDs.contains(id) else { return }
        repository.insert(SeedRemocaoModel(seedID: id))
    }

    private func validarNome(_ nome: String) throws {
        guard nome.count >= 2 && nome.count <= 24 else {
            throw CashUpDomainError.nomeInvalido
        }
    }
}
