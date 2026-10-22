import Foundation

final class RecommendedPlanningService: RecommendedPlanningServiceProtocol {
    func gerarPlanejamentoRecomendado(
        rendaMensal: Double,
        categoriasDisponiveis: [CategoriaModel]
    ) -> [RecommendedPlanningItem] {
        guard rendaMensal > 0 else { return [] }

        let categoriasDespesa = categoriasDisponiveis.filter { cat in
            let nomeNormalizado = cat.nome.folding(options: .diacriticInsensitive, locale: .current).lowercased()
            return !nomeNormalizado.contains("renda") && cat.id != SeedIDs.idRenda
        }

        guard !categoriasDespesa.isEmpty else { return [] }

        var itens: [RecommendedPlanningItem] = []

        var categoriasNecessidades: [CategoriaModel] = []
        var categoriasDesejos: [CategoriaModel] = []
        var categoriasPoupanca: [CategoriaModel] = []

        for cat in categoriasDespesa {
            let grupo = classificarGrupo(categoria: cat)
            switch grupo {
            case .necessidades:
                categoriasNecessidades.append(cat)
            case .desejos:
                categoriasDesejos.append(cat)
            case .futuroPoupanca:
                categoriasPoupanca.append(cat)
            }
        }

        if categoriasPoupanca.isEmpty, let diversos = categoriasDespesa.first(where: {
            $0.nome.folding(options: .diacriticInsensitive, locale: .current).lowercased().contains("diversos")
        }) {
            categoriasDesejos.removeAll { $0.id == diversos.id }
            categoriasNecessidades.removeAll { $0.id == diversos.id }
            categoriasPoupanca.append(diversos)
        }

        let totalNecessidades = rendaMensal * 0.50
        let totalDesejos = rendaMensal * 0.30
        let totalPoupanca = rendaMensal * 0.20

        itens.append(contentsOf: distribuirNecessidades(categorias: categoriasNecessidades, totalGrupo: totalNecessidades, rendaMensal: rendaMensal))
        itens.append(contentsOf: distribuirDesejos(categorias: categoriasDesejos, totalGrupo: totalDesejos))
        itens.append(contentsOf: distribuirPoupanca(categorias: categoriasPoupanca, totalGrupo: totalPoupanca))

        return itens
    }

    private func classificarGrupo(categoria: CategoriaModel) -> Regra503020Grupo {
        let nome = categoria.nome.folding(options: .diacriticInsensitive, locale: .current).lowercased()

        if nome.contains("moradia") || nome.contains("habitac") || nome.contains("casa") ||
            nome.contains("alimenta") || nome.contains("comida") || nome.contains("refeic") ||
            nome.contains("transporte") || nome.contains("saude") || nome.contains("educa") {
            return .necessidades
        }

        if nome.contains("invest") || nome.contains("poupanc") || nome.contains("reserva") || nome.contains("futuro") {
            return .futuroPoupanca
        }

        return .desejos
    }

    private func distribuirNecessidades(categorias: [CategoriaModel], totalGrupo: Double, rendaMensal: Double) -> [RecommendedPlanningItem] {
        guard !categorias.isEmpty else { return [] }

        var resultado: [RecommendedPlanningItem] = []

        let habitacao = categorias.first {
            let n = $0.nome.folding(options: .diacriticInsensitive, locale: .current).lowercased()
            return n.contains("habitac") || n.contains("moradia") || n.contains("casa")
        }

        let alimentacao = categorias.first {
            let n = $0.nome.folding(options: .diacriticInsensitive, locale: .current).lowercased()
            return n.contains("alimenta") || n.contains("comida") || n.contains("refeic")
        }

        let transporte = categorias.first {
            let n = $0.nome.folding(options: .diacriticInsensitive, locale: .current).lowercased()
            return n.contains("transporte")
        }

        if habitacao != nil || alimentacao != nil || transporte != nil {
            var alocado = 0.0
            if let habitacao {
                let valor = arredondar(rendaMensal * 0.25)
                alocado += valor
                let sub = escolherSubcategoriaPrincipal(categoria: habitacao, preferencias: ["aluguel", "contas", "habitacao"])
                resultado.append(RecommendedPlanningItem(categoria: habitacao, subcategoria: sub, valorSugerido: valor, grupo: .necessidades))
            }
            if let alimentacao {
                let valor = arredondar(rendaMensal * 0.15)
                alocado += valor
                let sub = escolherSubcategoriaPrincipal(categoria: alimentacao, preferencias: ["mantimentos", "supermercado", "comida"])
                resultado.append(RecommendedPlanningItem(categoria: alimentacao, subcategoria: sub, valorSugerido: valor, grupo: .necessidades))
            }
            if let transporte {
                let valor = arredondar(rendaMensal * 0.10)
                alocado += valor
                let sub = escolherSubcategoriaPrincipal(categoria: transporte, preferencias: ["transporte", "combustivel", "carro"])
                resultado.append(RecommendedPlanningItem(categoria: transporte, subcategoria: sub, valorSugerido: valor, grupo: .necessidades))
            }

            let restantes = categorias.filter { cat in
                cat.id != habitacao?.id && cat.id != alimentacao?.id && cat.id != transporte?.id
            }

            if !restantes.isEmpty {
                let sobra = max(totalGrupo - alocado, 0.0)
                let fatia = arredondar(sobra / Double(restantes.count))
                for cat in restantes {
                    let sub = escolherSubcategoriaPrincipal(categoria: cat, preferencias: [])
                    resultado.append(RecommendedPlanningItem(categoria: cat, subcategoria: sub, valorSugerido: fatia, grupo: .necessidades))
                }
            } else if alocado < totalGrupo && !resultado.isEmpty {
                let sobra = totalGrupo - alocado
                let extra = arredondar(sobra / Double(resultado.count))
                for i in 0..<resultado.count {
                    resultado[i].valorSugerido += extra
                }
            }
        } else {
            let fatia = arredondar(totalGrupo / Double(categorias.count))
            for cat in categorias {
                let sub = escolherSubcategoriaPrincipal(categoria: cat, preferencias: [])
                resultado.append(RecommendedPlanningItem(categoria: cat, subcategoria: sub, valorSugerido: fatia, grupo: .necessidades))
            }
        }

        return resultado
    }

    private func distribuirDesejos(categorias: [CategoriaModel], totalGrupo: Double) -> [RecommendedPlanningItem] {
        guard !categorias.isEmpty else { return [] }

        var resultado: [RecommendedPlanningItem] = []
        let fatia = arredondar(totalGrupo / Double(categorias.count))

        for cat in categorias {
            let sub = escolherSubcategoriaPrincipal(categoria: cat, preferencias: ["lazer", "entretenimento", "compras", "restaurante"])
            resultado.append(RecommendedPlanningItem(categoria: cat, subcategoria: sub, valorSugerido: fatia, grupo: .desejos))
        }

        return resultado
    }

    private func distribuirPoupanca(categorias: [CategoriaModel], totalGrupo: Double) -> [RecommendedPlanningItem] {
        guard !categorias.isEmpty else { return [] }

        var resultado: [RecommendedPlanningItem] = []
        let fatia = arredondar(totalGrupo / Double(categorias.count))

        for cat in categorias {
            let sub = escolherSubcategoriaPrincipal(categoria: cat, preferencias: ["reserva", "poupanca", "investimento", "geral"])
            resultado.append(RecommendedPlanningItem(categoria: cat, subcategoria: sub, valorSugerido: fatia, grupo: .futuroPoupanca))
        }

        return resultado
    }

    private func escolherSubcategoriaPrincipal(categoria: CategoriaModel, preferencias: [String]) -> SubcategoriaModel? {
        let subs = categoria.subcategorias
        guard !subs.isEmpty else { return nil }

        for pref in preferencias {
            if let encontrada = subs.first(where: {
                $0.nome.folding(options: .diacriticInsensitive, locale: .current).lowercased().contains(pref)
            }) {
                return encontrada
            }
        }

        return subs.first
    }

    private func arredondar(_ valor: Double) -> Double {
        max((valor / 5.0).rounded() * 5.0, 0.0)
    }
}
