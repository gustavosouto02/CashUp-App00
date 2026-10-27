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

        if categoriasPoupanca.isEmpty, let fallback = categoriasDespesa.last {
            categoriasDesejos.removeAll { $0.id == fallback.id }
            categoriasNecessidades.removeAll { $0.id == fallback.id }
            categoriasPoupanca.append(fallback)
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
        if categoria.id == SeedIDs.idHabitacao ||
           categoria.id == SeedIDs.idComidasEBebidas ||
           categoria.id == SeedIDs.idTransporte {
            return .necessidades
        }

        let nome = categoria.nome.folding(options: .diacriticInsensitive, locale: .current).lowercased()

        if nome.contains("moradia") || nome.contains("habitac") || nome.contains("casa") ||
            nome.contains("alimenta") || nome.contains("comida") || nome.contains("refeic") ||
            nome.contains("transporte") || nome.contains("saude") || nome.contains("educa") ||
            nome.contains("housing") || nome.contains("food") || nome.contains("grocer") ||
            nome.contains("transit") || nome.contains("health") || nome.contains("vivienda") ||
            nome.contains("salud") || nome.contains("educacion") {
            return .necessidades
        }

        if nome.contains("invest") || nome.contains("poupanc") || nome.contains("reserva") || nome.contains("futuro") ||
            nome.contains("saving") || nome.contains("emergency") || nome.contains("ahorro") {
            return .futuroPoupanca
        }

        return .desejos
    }

    private func distribuirNecessidades(categorias: [CategoriaModel], totalGrupo: Double, rendaMensal: Double) -> [RecommendedPlanningItem] {
        guard !categorias.isEmpty else { return [] }

        var resultado: [RecommendedPlanningItem] = []

        let habitacao = categorias.first { cat in
            if cat.id == SeedIDs.idHabitacao { return true }
            let n = cat.nome.folding(options: .diacriticInsensitive, locale: .current).lowercased()
            return n.contains("habitac") || n.contains("moradia") || n.contains("casa") || n.contains("housing") || n.contains("vivienda")
        }

        let alimentacao = categorias.first { cat in
            if cat.id == SeedIDs.idComidasEBebidas { return true }
            let n = cat.nome.folding(options: .diacriticInsensitive, locale: .current).lowercased()
            return n.contains("alimenta") || n.contains("comida") || n.contains("refeic") || n.contains("food")
        }

        let transporte = categorias.first { cat in
            if cat.id == SeedIDs.idTransporte { return true }
            let n = cat.nome.folding(options: .diacriticInsensitive, locale: .current).lowercased()
            return n.contains("transporte") || n.contains("transit")
        }

        if habitacao != nil || alimentacao != nil || transporte != nil {
            var alocado = 0.0
            if let habitacao {
                let valor = arredondar(rendaMensal * 0.25)
                alocado += valor
                let sub = escolherSubcategoriaPrincipal(categoria: habitacao, preferencias: ["aluguel", "rent", "alquiler", "contas", "bills", "facturas", "habitacao", "housing", "vivienda"])
                resultado.append(RecommendedPlanningItem(categoria: habitacao, subcategoria: sub, valorSugerido: valor, grupo: .necessidades))
            }
            if let alimentacao {
                let valor = arredondar(rendaMensal * 0.15)
                alocado += valor
                let sub = escolherSubcategoriaPrincipal(categoria: alimentacao, preferencias: ["mantimentos", "groceries", "supermercado", "comida", "food"])
                resultado.append(RecommendedPlanningItem(categoria: alimentacao, subcategoria: sub, valorSugerido: valor, grupo: .necessidades))
            }
            if let transporte {
                let valor = arredondar(rendaMensal * 0.10)
                alocado += valor
                let sub = escolherSubcategoriaPrincipal(categoria: transporte, preferencias: ["transporte", "transportation", "combustivel", "gas", "gasolina", "carro", "car", "auto"])
                resultado.append(RecommendedPlanningItem(categoria: transporte, subcategoria: sub, valorSugerido: valor, grupo: .necessidades))
            }

            let restantes = categorias.filter { cat in
                cat.id != habitacao?.id && cat.id != alimentacao?.id && cat.id != transporte?.id
            }

            if !restantes.isEmpty {
                var sobra = max(totalGrupo - alocado, 0.0)
                for (index, cat) in restantes.enumerated() {
                    let sub = escolherSubcategoriaPrincipal(categoria: cat, preferencias: [])
                    let valor: Double
                    if index == restantes.count - 1 {
                        valor = max((sobra * 100).rounded() / 100.0, 0.0)
                    } else {
                        let fatia = arredondar(sobra / Double(restantes.count - index))
                        valor = min(fatia, sobra)
                        sobra -= valor
                    }
                    resultado.append(RecommendedPlanningItem(categoria: cat, subcategoria: sub, valorSugerido: valor, grupo: .necessidades))
                }
            } else if alocado < totalGrupo && !resultado.isEmpty {
                let sobra = totalGrupo - alocado
                resultado[resultado.count - 1].valorSugerido += (sobra * 100).rounded() / 100.0
            }
        } else {
            var restante = (totalGrupo * 100).rounded() / 100.0
            for (index, cat) in categorias.enumerated() {
                let sub = escolherSubcategoriaPrincipal(categoria: cat, preferencias: [])
                let valor: Double
                if index == categorias.count - 1 {
                    valor = max((restante * 100).rounded() / 100.0, 0.0)
                } else {
                    let fatia = arredondar(totalGrupo / Double(categorias.count))
                    valor = min(fatia, restante)
                    restante -= valor
                }
                resultado.append(RecommendedPlanningItem(categoria: cat, subcategoria: sub, valorSugerido: valor, grupo: .necessidades))
            }
        }

        return resultado
    }

    private func distribuirDesejos(categorias: [CategoriaModel], totalGrupo: Double) -> [RecommendedPlanningItem] {
        guard !categorias.isEmpty else { return [] }

        var resultado: [RecommendedPlanningItem] = []
        var restante = (totalGrupo * 100).rounded() / 100.0

        for (index, cat) in categorias.enumerated() {
            let sub = escolherSubcategoriaPrincipal(categoria: cat, preferencias: ["lazer", "entretenimento", "compras", "restaurante"])
            let valor: Double
            if index == categorias.count - 1 {
                valor = max((restante * 100).rounded() / 100.0, 0.0)
            } else {
                let calculado = arredondar(totalGrupo / Double(categorias.count))
                valor = min(calculado, restante)
                restante -= valor
            }
            resultado.append(RecommendedPlanningItem(categoria: cat, subcategoria: sub, valorSugerido: valor, grupo: .desejos))
        }

        return resultado
    }

    private func distribuirPoupanca(categorias: [CategoriaModel], totalGrupo: Double) -> [RecommendedPlanningItem] {
        guard !categorias.isEmpty else { return [] }

        var resultado: [RecommendedPlanningItem] = []
        var restante = (totalGrupo * 100).rounded() / 100.0

        for (index, cat) in categorias.enumerated() {
            let sub = escolherSubcategoriaPrincipal(categoria: cat, preferencias: ["reserva", "emergency", "fund", "poupanca", "savings", "ahorro", "investimento", "investment", "inversiones", "diversos", "miscellaneous", "varios", "outros", "geral"])
            let valor: Double
            if index == categorias.count - 1 {
                valor = max((restante * 100).rounded() / 100.0, 0.0)
            } else {
                let calculado = arredondar(totalGrupo / Double(categorias.count))
                valor = min(calculado, restante)
                restante -= valor
            }
            resultado.append(RecommendedPlanningItem(categoria: cat, subcategoria: sub, valorSugerido: valor, grupo: .futuroPoupanca))
        }

        return resultado
    }

    private func escolherSubcategoriaPrincipal(categoria: CategoriaModel, preferencias: [String]) -> SubcategoriaModel? {
        let subs = categoria.subcategorias ?? []
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
