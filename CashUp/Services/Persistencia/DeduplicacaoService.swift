import Foundation
import SwiftData

/// Deduplicação determinística: todo aparelho que vê as mesmas cópias escolhe o mesmo sobrevivente,
/// o de menor `(criadoEm, instanciaID)`. Os campos editáveis vêm da cópia com o maior `atualizadoEm`.
final class DeduplicacaoService: DeduplicacaoServiceProtocol {
    @discardableResult
    func deduplicar(em context: ModelContext) throws -> Bool {
        var houveAlteracao = false
        houveAlteracao = try deduplicarCategorias(em: context) || houveAlteracao
        houveAlteracao = try deduplicarSubcategorias(em: context) || houveAlteracao
        houveAlteracao = try aplicarLapides(em: context) || houveAlteracao
        houveAlteracao = try deduplicarCategoriasPlanejadas(em: context) || houveAlteracao
        houveAlteracao = try deduplicarSubcategoriasPlanejadas(em: context) || houveAlteracao
        houveAlteracao = try deduplicarTransacoes(em: context) || houveAlteracao

        if houveAlteracao {
            try context.save()
        }
        return houveAlteracao
    }

    private func deduplicarCategorias(em context: ModelContext) throws -> Bool {
        let grupos = gruposDuplicados(try context.fetch(FetchDescriptor<CategoriaModel>()), por: \.id)
        guard !grupos.isEmpty else { return false }
        let planejadas = try context.fetch(FetchDescriptor<CategoriaPlanejadaModel>())

        for grupo in grupos {
            let (sobrevivente, perdedores) = separar(grupo, criadoEm: \.criadoEm, instanciaID: \.instanciaID)
            let maisRecente = grupo.max { $0.atualizadoEm < $1.atualizadoEm } ?? sobrevivente
            sobrevivente.nome = maisRecente.nome
            sobrevivente.icon = maisRecente.icon
            sobrevivente.redComponent = maisRecente.redComponent
            sobrevivente.greenComponent = maisRecente.greenComponent
            sobrevivente.blueComponent = maisRecente.blueComponent
            sobrevivente.atualizadoEm = maisRecente.atualizadoEm

            for perdedor in perdedores {
                (perdedor.subcategorias ?? []).forEach { $0.categoria = sobrevivente }
                (perdedor.transacoes ?? []).forEach { $0.categoria = sobrevivente }
                planejadas
                    .filter { $0.categoriaOriginal?.persistentModelID == perdedor.persistentModelID }
                    .forEach { $0.categoriaOriginal = sobrevivente }
                context.delete(perdedor)
            }
        }
        return true
    }

    private func deduplicarSubcategorias(em context: ModelContext) throws -> Bool {
        let grupos = gruposDuplicados(try context.fetch(FetchDescriptor<SubcategoriaModel>()), por: \.id)
        guard !grupos.isEmpty else { return false }
        let planejadas = try context.fetch(FetchDescriptor<SubcategoriaPlanejadaModel>())

        for grupo in grupos {
            let (sobrevivente, perdedores) = separar(grupo, criadoEm: \.criadoEm, instanciaID: \.instanciaID)
            let maisRecente = grupo.max { $0.atualizadoEm < $1.atualizadoEm } ?? sobrevivente
            sobrevivente.nome = maisRecente.nome
            sobrevivente.icon = maisRecente.icon
            sobrevivente.atualizadoEm = maisRecente.atualizadoEm
            sobrevivente.usageCount = grupo.reduce(0) { $0 + $1.usageCount }

            for perdedor in perdedores {
                (perdedor.transacoes ?? []).forEach { $0.subcategoria = sobrevivente }
                planejadas
                    .filter { $0.subcategoriaOriginal?.persistentModelID == perdedor.persistentModelID }
                    .forEach { $0.subcategoriaOriginal = sobrevivente }
                context.delete(perdedor)
            }
        }
        return true
    }

    /// Item do seed com lápide some se não tiver transações; se tiver, o uso real vence e a lápide é descartada.
    private func aplicarLapides(em context: ModelContext) throws -> Bool {
        let lapides = try context.fetch(FetchDescriptor<SeedRemocaoModel>())
        guard !lapides.isEmpty else { return false }

        let categorias = Dictionary(grouping: try context.fetch(FetchDescriptor<CategoriaModel>()), by: \.id)
        let subcategorias = Dictionary(grouping: try context.fetch(FetchDescriptor<SubcategoriaModel>()), by: \.id)
        var houveAlteracao = false

        for (seedID, copias) in Dictionary(grouping: lapides, by: \.seedID) {
            let (lapide, extras) = separar(copias, criadoEm: \.criadoEm, instanciaID: \.instanciaID)
            for extra in extras {
                context.delete(extra)
                houveAlteracao = true
            }

            if let categoria = categorias[seedID]?.first {
                if seedID != SeedIDs.idRenda && !categoriaTemTransacoes(categoria) {
                    context.delete(categoria)
                } else {
                    context.delete(lapide)
                }
                houveAlteracao = true
            } else if let subcategoria = subcategorias[seedID]?.first {
                if (subcategoria.transacoes ?? []).isEmpty {
                    context.delete(subcategoria)
                } else {
                    context.delete(lapide)
                }
                houveAlteracao = true
            }
        }
        return houveAlteracao
    }

    private func deduplicarCategoriasPlanejadas(em context: ModelContext) throws -> Bool {
        let comCategoria = try context.fetch(FetchDescriptor<CategoriaPlanejadaModel>()).filter { $0.categoriaOriginal != nil }
        let grupos = gruposDuplicados(comCategoria) { ChaveCategoriaPlanejada(mesAno: $0.mesAno, categoriaID: $0.categoriaOriginal?.id) }
        guard !grupos.isEmpty else { return false }

        for grupo in grupos {
            let (sobrevivente, perdedores) = separar(grupo, criadoEm: \.criadoEm, instanciaID: \.instanciaID)
            for perdedor in perdedores {
                (perdedor.subcategoriasPlanejadas ?? []).forEach { $0.categoriaPlanejada = sobrevivente }
                context.delete(perdedor)
            }
        }
        return true
    }

    private func deduplicarSubcategoriasPlanejadas(em context: ModelContext) throws -> Bool {
        let comVinculo = try context.fetch(FetchDescriptor<SubcategoriaPlanejadaModel>())
            .filter { $0.categoriaPlanejada != nil && $0.subcategoriaOriginal != nil }
        let grupos = gruposDuplicados(comVinculo) {
            ChaveSubcategoriaPlanejada(categoriaPlanejada: $0.categoriaPlanejada?.persistentModelID, subcategoriaID: $0.subcategoriaOriginal?.id)
        }
        guard !grupos.isEmpty else { return false }

        for grupo in grupos {
            let (sobrevivente, perdedores) = separar(grupo, criadoEm: \.criadoEm, instanciaID: \.instanciaID)
            let maisRecente = grupo.max { $0.atualizadoEm < $1.atualizadoEm } ?? sobrevivente
            sobrevivente.valorPlanejado = maisRecente.valorPlanejado
            sobrevivente.atualizadoEm = maisRecente.atualizadoEm
            perdedores.forEach(context.delete)
        }
        return true
    }

    private func deduplicarTransacoes(em context: ModelContext) throws -> Bool {
        let grupos = gruposDuplicados(try context.fetch(FetchDescriptor<ExpenseModel>()), por: \.id)
        guard !grupos.isEmpty else { return false }

        for grupo in grupos {
            separar(grupo, criadoEm: \.criadoEm, instanciaID: \.instanciaID).perdedores.forEach(context.delete)
        }
        return true
    }

    private func categoriaTemTransacoes(_ categoria: CategoriaModel) -> Bool {
        if !(categoria.transacoes ?? []).isEmpty { return true }
        return (categoria.subcategorias ?? []).contains { !($0.transacoes ?? []).isEmpty }
    }

    private func gruposDuplicados<T, Chave: Hashable>(_ itens: [T], por chave: (T) -> Chave) -> [[T]] {
        Dictionary(grouping: itens, by: chave).values.filter { $0.count > 1 }
    }

    private func separar<T>(
        _ grupo: [T],
        criadoEm: KeyPath<T, Date>,
        instanciaID: KeyPath<T, UUID>
    ) -> (sobrevivente: T, perdedores: [T]) {
        let ordenado = grupo.sorted {
            ($0[keyPath: criadoEm], $0[keyPath: instanciaID].uuidString) < ($1[keyPath: criadoEm], $1[keyPath: instanciaID].uuidString)
        }
        return (ordenado[0], Array(ordenado.dropFirst()))
    }
}

private struct ChaveCategoriaPlanejada: Hashable {
    let mesAno: Date
    let categoriaID: UUID?
}

private struct ChaveSubcategoriaPlanejada: Hashable {
    let categoriaPlanejada: PersistentIdentifier?
    let subcategoriaID: UUID?
}
