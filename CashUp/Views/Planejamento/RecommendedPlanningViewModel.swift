import Combine
import Foundation
import SwiftData
import SwiftUI

@MainActor
final class RecommendedPlanningViewModel: ObservableObject {
    private let planningRepository: PlanningRepositoryProtocol
    private let categoriaRepository: CategoriaRepositoryProtocol
    private let expenseRepository: ExpenseRepositoryProtocol
    private let service: RecommendedPlanningServiceProtocol

    @Published var rendaInformadaCentavos: Int64 = 0
    @Published var rendaDetectadaCentavos: Int64 = 0
    @Published var itensRecomendados: [RecommendedPlanningItem] = []
    @Published var categoriasDisponiveis: [CategoriaModel] = []
    @Published var substituirPlanejamentoExistente: Bool = true
    @Published var temPlanejamentoExistente: Bool = false
    @Published var isCarregando: Bool = false
    @Published var isAplicando: Bool = false
    @Published var showAlertaSucesso: Bool = false
    @Published var showAlertaErro: Bool = false
    @Published var mensagemErro: String = ""

    var temRendaDetectada: Bool {
        rendaDetectadaCentavos > 0
    }

    var totalRecomendado: Int64 {
        itensRecomendados.reduce(0) { $0 + $1.valorSugeridoCentavos }
    }

    var percentualRendaAlocado: Double {
        Centavos.razao(totalRecomendado, de: rendaInformadaCentavos) * 100.0
    }

    init(
        planningRepository: PlanningRepositoryProtocol,
        categoriaRepository: CategoriaRepositoryProtocol,
        expenseRepository: ExpenseRepositoryProtocol,
        service: RecommendedPlanningServiceProtocol = RecommendedPlanningService()
    ) {
        self.planningRepository = planningRepository
        self.categoriaRepository = categoriaRepository
        self.expenseRepository = expenseRepository
        self.service = service
    }

    convenience init(modelContext: ModelContext) {
        self.init(
            planningRepository: SwiftDataPlanningRepository(context: modelContext),
            categoriaRepository: SwiftDataCategoriaRepository(context: modelContext),
            expenseRepository: SwiftDataExpenseRepository(context: modelContext),
            service: RecommendedPlanningService()
        )
    }

    func carregarDados(mes: Date) {
        isCarregando = true
        defer { isCarregando = false }

        do {
            categoriasDisponiveis = try categoriaRepository.fetchCategorias(filtro: nil)
        } catch {
            CashUpLogger.persistence.error("Erro ao carregar categorias para planejamento recomendado: \(error.localizedDescription, privacy: .public)")
            categoriasDisponiveis = []
        }

        let rendaAuto = detectarRenda(mes: mes)
        rendaDetectadaCentavos = rendaAuto
        if rendaInformadaCentavos <= 0 {
            rendaInformadaCentavos = rendaAuto > 0 ? rendaAuto : 300_000
        }

        verificarPlanejamentoExistente(mes: mes)
        recalcular()
    }

    func detectarRenda(mes: Date) -> Int64 {
        let inicioMes = mes.startOfMonth()
        guard let intervalo = Calendar.current.dateInterval(of: .month, for: inicioMes) else { return 0 }

        do {
            let todas = try expenseRepository.fetchAll()
            let ocorrenciasReceita = todas
                .flatMap { $0.generateOccurrences(forDateInterval: intervalo, calendar: .current) }
                .filter { $0.isIncome }
            return ocorrenciasReceita.reduce(0) { $0 + $1.amountInCents }
        } catch {
            CashUpLogger.persistence.error("Erro ao detectar renda do mês: \(error.localizedDescription, privacy: .public)")
            return 0
        }
    }

    func verificarPlanejamentoExistente(mes: Date) {
        do {
            let existentes = try planningRepository.fetchCategoriasPlanejadas(mes: mes.startOfMonth())
            temPlanejamentoExistente = !existentes.isEmpty
        } catch {
            temPlanejamentoExistente = false
        }
    }

    func recalcular() {
        guard rendaInformadaCentavos > 0 else {
            itensRecomendados = []
            return
        }

        itensRecomendados = service.gerarPlanejamentoRecomendado(
            rendaMensalCentavos: rendaInformadaCentavos,
            categoriasDisponiveis: categoriasDisponiveis
        )
    }

    func usarRendaDetectada() {
        guard rendaDetectadaCentavos > 0 else { return }
        rendaInformadaCentavos = rendaDetectadaCentavos
        recalcular()
    }

    func atualizarValorItem(id: UUID, novoValorCentavos: Int64) {
        guard let index = itensRecomendados.firstIndex(where: { $0.id == id }) else { return }
        let valorLimpo = max(novoValorCentavos, 0)
        itensRecomendados[index].valorSugeridoCentavos = valorLimpo

        rebalancearAposEdicao(itemEditadoId: id, novoValor: valorLimpo)
    }

    private func rebalancearAposEdicao(itemEditadoId: UUID, novoValor: Int64) {
        guard let index = itensRecomendados.firstIndex(where: { $0.id == itemEditadoId }) else { return }
        let itemEditado = itensRecomendados[index]
        let grupo = itemEditado.grupo

        if grupo == .futuroPoupanca {
            let valorClamp = min(novoValor, rendaInformadaCentavos)
            itensRecomendados[index].valorSugeridoCentavos = valorClamp
            let sobra = max(rendaInformadaCentavos - valorClamp, 0)
            distribuirEntre(grupos: [.desejos, .necessidades], totalDisponivel: sobra)
            garantirTetoRenda(itemEditadoId: itemEditadoId)
            return
        }

        // Para necessidades ou estilo de vida: NUNCA mexe no que é para guardar!
        let totalPoupanca = totalPorGrupo(.futuroPoupanca)
        let orcamentoNaoPoupanca = max(rendaInformadaCentavos - totalPoupanca, 0)

        // Limita o item editado para nunca ultrapassar a renda base disponível
        let valorAjustado = min(novoValor, orcamentoNaoPoupanca)
        itensRecomendados[index].valorSugeridoCentavos = valorAjustado

        let orcamentoRestante = max(orcamentoNaoPoupanca - valorAjustado, 0)

        let outrosMesmoGrupo = itensRecomendados.filter { $0.grupo == grupo && $0.id != itemEditadoId }
        let outroGrupo: Regra503020Grupo = (grupo == .necessidades) ? .desejos : .necessidades
        let itensOutroGrupo = itensRecomendados.filter { $0.grupo == outroGrupo }

        let targetMesmoGrupo = max(Centavos.fracao(rendaInformadaCentavos, percentual: grupo.percentualAlvo) - valorAjustado, 0)

        if !outrosMesmoGrupo.isEmpty {
            if orcamentoRestante >= targetMesmoGrupo {
                distribuirValor(entre: outrosMesmoGrupo, total: targetMesmoGrupo)
                let sobraOutroGrupo = min(orcamentoRestante - targetMesmoGrupo, Centavos.fracao(rendaInformadaCentavos, percentual: outroGrupo.percentualAlvo))
                distribuirValor(entre: itensOutroGrupo, total: sobraOutroGrupo)
            } else {
                zerarItens(itensOutroGrupo)
                distribuirValor(entre: outrosMesmoGrupo, total: orcamentoRestante)
            }
        } else {
            distribuirValor(entre: itensOutroGrupo, total: min(orcamentoRestante, Centavos.fracao(rendaInformadaCentavos, percentual: outroGrupo.percentualAlvo)))
        }

        garantirTetoRenda(itemEditadoId: itemEditadoId)
    }

    private func distribuirValor(entre itens: [RecommendedPlanningItem], total: Int64) {
        guard !itens.isEmpty else { return }
        guard total > 0 else {
            zerarItens(itens)
            return
        }

        let totalLimpo = total
        let somaAtual = itens.reduce(Int64(0)) { $0 + $1.valorSugeridoCentavos }
        var restante = totalLimpo

        for (index, item) in itens.enumerated() {
            guard let globalIdx = itensRecomendados.firstIndex(where: { $0.id == item.id }) else { continue }
            if index == itens.count - 1 {
                itensRecomendados[globalIdx].valorSugeridoCentavos = max(restante, 0)
            } else {
                let fatia: Int64
                if somaAtual > 0 {
                    fatia = Centavos.proporcao(totalLimpo, parte: item.valorSugeridoCentavos, de: somaAtual)
                } else {
                    fatia = Centavos.dividir(totalLimpo, por: itens.count)
                }
                let calculado = arredondar(fatia)
                let valor = min(calculado, restante)
                itensRecomendados[globalIdx].valorSugeridoCentavos = valor
                restante -= valor
            }
        }
    }

    private func zerarItens(_ itens: [RecommendedPlanningItem]) {
        for item in itens {
            if let idx = itensRecomendados.firstIndex(where: { $0.id == item.id }) {
                itensRecomendados[idx].valorSugeridoCentavos = 0
            }
        }
    }

    private func distribuirEntre(grupos: [Regra503020Grupo], totalDisponivel: Int64) {
        let itensGrupos = itensRecomendados.filter { grupos.contains($0.grupo) }
        distribuirValor(entre: itensGrupos, total: totalDisponivel)
    }

    private func garantirTetoRenda(itemEditadoId: UUID) {
        let total = totalRecomendado
        let teto = rendaInformadaCentavos
        guard total > teto else { return }
        var excesso = total - teto

        // Diminui primeiro em desejos (estilo de vida)
        for idx in itensRecomendados.indices where itensRecomendados[idx].grupo == .desejos && itensRecomendados[idx].id != itemEditadoId {
            let itemVal = itensRecomendados[idx].valorSugeridoCentavos
            let deducao = min(itemVal, excesso)
            itensRecomendados[idx].valorSugeridoCentavos = itemVal - deducao
            excesso -= deducao
            if excesso <= 0 { return }
        }

        // Se ainda sobrou excesso, diminui em necessidades (exceto o item editado)
        for idx in itensRecomendados.indices where itensRecomendados[idx].grupo == .necessidades && itensRecomendados[idx].id != itemEditadoId {
            let itemVal = itensRecomendados[idx].valorSugeridoCentavos
            let deducao = min(itemVal, excesso)
            itensRecomendados[idx].valorSugeridoCentavos = itemVal - deducao
            excesso -= deducao
            if excesso <= 0 { return }
        }

        // Se mesmo assim sobrou, ajusta o próprio item
        if excesso > 0, let idx = itensRecomendados.firstIndex(where: { $0.id == itemEditadoId }) {
            itensRecomendados[idx].valorSugeridoCentavos = max(itensRecomendados[idx].valorSugeridoCentavos - excesso, 0)
        }
    }

    /// Os valores sugeridos são arredondados para múltiplos de R$ 5,00.
    private func arredondar(_ valor: Int64) -> Int64 {
        Centavos.arredondar(valor, multiploDe: 500)
    }

    func atualizarSubcategoriaItem(id: UUID, novaSubcategoria: SubcategoriaModel) {
        guard let index = itensRecomendados.firstIndex(where: { $0.id == id }) else { return }
        itensRecomendados[index].subcategoria = novaSubcategoria
    }

    @discardableResult
    func adicionarItem(subcategoria: SubcategoriaModel, grupo: Regra503020Grupo) -> Bool {
        guard let categoria = subcategoria.categoria else { return false }
        guard !idsSubcategoriasUsadas().contains(subcategoria.id) else { return false }
        itensRecomendados.append(
            RecommendedPlanningItem(categoria: categoria, subcategoria: subcategoria, valorSugeridoCentavos: 0, grupo: grupo)
        )
        rebalancearAposMudancaDeItens(grupoAfetado: grupo)
        return true
    }

    func idsSubcategoriasUsadas(excluindo itemId: UUID? = nil) -> Set<UUID> {
        Set(itensRecomendados.filter { $0.id != itemId }.compactMap { $0.subcategoria?.id })
    }

    func removerItem(id: UUID) {
        guard let itemParaRemover = itensRecomendados.first(where: { $0.id == id }) else { return }
        let grupo = itemParaRemover.grupo
        itensRecomendados.removeAll { $0.id == id }

        rebalancearAposMudancaDeItens(grupoAfetado: grupo)
    }

    private func rebalancearAposMudancaDeItens(grupoAfetado: Regra503020Grupo) {
        if grupoAfetado == .futuroPoupanca {
            let itensPoupanca = itensRecomendados.filter { $0.grupo == .futuroPoupanca }
            let targetPoupanca = Centavos.fracao(rendaInformadaCentavos, percentual: Regra503020Grupo.futuroPoupanca.percentualAlvo)
            if !itensPoupanca.isEmpty {
                distribuirValor(entre: itensPoupanca, total: targetPoupanca)
            } else {
                distribuirEntre(grupos: [.necessidades, .desejos], totalDisponivel: rendaInformadaCentavos)
            }
            garantirTetoRenda(itemEditadoId: UUID())
            return
        }

        let totalPoupanca = totalPorGrupo(.futuroPoupanca)
        let orcamentoNaoPoupanca = max(rendaInformadaCentavos - totalPoupanca, 0)

        let itensMesmoGrupo = itensRecomendados.filter { $0.grupo == grupoAfetado }
        let outroGrupo: Regra503020Grupo = (grupoAfetado == .necessidades) ? .desejos : .necessidades
        let itensOutroGrupo = itensRecomendados.filter { $0.grupo == outroGrupo }

        let targetMesmoGrupo = Centavos.fracao(rendaInformadaCentavos, percentual: grupoAfetado.percentualAlvo)
        let targetOutroGrupo = Centavos.fracao(rendaInformadaCentavos, percentual: outroGrupo.percentualAlvo)

        if !itensMesmoGrupo.isEmpty {
            distribuirValor(entre: itensMesmoGrupo, total: min(targetMesmoGrupo, orcamentoNaoPoupanca))
            let sobraOutro = max(orcamentoNaoPoupanca - totalPorGrupo(grupoAfetado), 0)
            distribuirValor(entre: itensOutroGrupo, total: min(sobraOutro, targetOutroGrupo))
        } else {
            distribuirValor(entre: itensOutroGrupo, total: orcamentoNaoPoupanca)
        }

        garantirTetoRenda(itemEditadoId: UUID())
    }

    func totalPorGrupo(_ grupo: Regra503020Grupo) -> Int64 {
        itensRecomendados
            .filter { $0.grupo == grupo }
            .reduce(0) { $0 + $1.valorSugeridoCentavos }
    }

    func percentualPorGrupo(_ grupo: Regra503020Grupo) -> Double {
        Centavos.razao(totalPorGrupo(grupo), de: rendaInformadaCentavos) * 100.0
    }

    func itens(doGrupo grupo: Regra503020Grupo) -> [RecommendedPlanningItem] {
        itensRecomendados.filter { $0.grupo == grupo }
    }

    func aplicarAoPlanejamento(mes: Date) -> Bool {
        guard !itensRecomendados.isEmpty else { return false }
        isAplicando = true
        defer { isAplicando = false }

        let mesReferencia = mes.startOfMonth()

        do {
            if substituirPlanejamentoExistente {
                let existentes = try planningRepository.fetchCategoriasPlanejadas(mes: mesReferencia)
                for cat in existentes {
                    planningRepository.delete(cat)
                }
                try planningRepository.save()
            }

            var mapaCategorias: [UUID: CategoriaPlanejadaModel] = [:]

            if !substituirPlanejamentoExistente {
                let existentes = try planningRepository.fetchCategoriasPlanejadas(mes: mesReferencia)
                for cat in existentes {
                    if let origId = cat.categoriaOriginal?.id {
                        mapaCategorias[origId] = cat
                    }
                }
            }

            for item in itensRecomendados where item.valorSugeridoCentavos > 0 {
                let catId = item.categoria.id
                let categoriaPlanejada: CategoriaPlanejadaModel

                if let jaCriada = mapaCategorias[catId] {
                    categoriaPlanejada = jaCriada
                } else {
                    let nova = CategoriaPlanejadaModel(mesAno: mesReferencia, categoriaOriginal: item.categoria)
                    nova.subcategoriasPlanejadas = []
                    planningRepository.insert(nova)
                    mapaCategorias[catId] = nova
                    categoriaPlanejada = nova
                }

                if let subOriginal = item.subcategoria {
                    if categoriaPlanejada.subcategoriasPlanejadas == nil {
                        categoriaPlanejada.subcategoriasPlanejadas = []
                    }

                    if let subExistente = categoriaPlanejada.subcategoriasPlanejadas?.first(where: {
                        $0.subcategoriaOriginal?.id == subOriginal.id
                    }) {
                        subExistente.valorPlanejadoCentavos = item.valorSugeridoCentavos
                        subExistente.atualizadoEm = Date()
                    } else {
                        let novaSub = SubcategoriaPlanejadaModel(
                            valorPlanejadoCentavos: item.valorSugeridoCentavos,
                            subcategoriaOriginal: subOriginal,
                            categoriaPlanejada: categoriaPlanejada
                        )
                        categoriaPlanejada.subcategoriasPlanejadas?.append(novaSub)
                    }
                }
            }

            try planningRepository.save()
            showAlertaSucesso = true
            return true
        } catch {
            CashUpLogger.persistence.error("Erro ao aplicar planejamento recomendado: \(error.localizedDescription, privacy: .public)")
            mensagemErro = "Não foi possível aplicar o planejamento recomendado. Tente novamente."
            showAlertaErro = true
            return false
        }
    }
}
