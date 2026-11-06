import Combine
import Foundation
import SwiftData

@MainActor
final class PlanningViewModel: ObservableObject {
    private let repository: PlanningRepositoryProtocol

    @Published var selectedTab: Int = 0
    @Published var currentMonth: Date

    @Published var copyPlanningAlertTitle: String = ""
    @Published var copyPlanningAlertMessage: String = ""
    @Published var showCopyConfirmationAlert: Bool = false
    @Published var showCopyResultAlert: Bool = false
    @Published var copyResultAlertTitle: String = ""
    @Published var copyResultAlertMessage: String = ""

    init(repository: PlanningRepositoryProtocol) {
        self.repository = repository
        self._currentMonth = Published(initialValue: Date().startOfMonth())
    }

    convenience init(modelContext: ModelContext) {
        self.init(repository: SwiftDataPlanningRepository(context: modelContext))
    }

    func getCategoriasPlanejadasForCurrentMonth() -> [CategoriaPlanejadaModel] {
        do {
            return try repository.fetchCategoriasPlanejadas(mes: currentMonth)
        } catch {
            CashUpLogger.persistence.error("Erro ao buscar CategoriaPlanejadaModel para o mês: \(error.localizedDescription, privacy: .public)")
            return []
        }
    }

    private func salvarContexto(operacao: String = "desconhecida") -> Bool {
        do {
            try repository.save()
            objectWillChange.send()
            return true
        } catch {
            CashUpLogger.persistence.error("Erro ao salvar contexto após \(operacao, privacy: .public): \(error.localizedDescription, privacy: .public)")
            return false
        }
    }

    @discardableResult
    func salvarAlteracoes() -> Bool {
        salvarContexto(operacao: "salvarAlteracoes")
    }

    @discardableResult
    func alterarSubcategoria(subItem: SubcategoriaPlanejadaModel, para novaSub: SubcategoriaModel) -> Bool {
        guard let categoriaPlanejada = subItem.categoriaPlanejada else { return false }

        let jaExiste = categoriaPlanejada.subcategoriasPlanejadas?.contains(where: {
            $0.id != subItem.id && $0.subcategoriaOriginal?.id == novaSub.id
        }) == true

        if jaExiste {
            return false
        }

        subItem.subcategoriaOriginal = novaSub
        return salvarContexto(operacao: "alterarSubcategoria")
    }

    func adicionarSubcategoriaAoPlanejamento(subcategoriaModel: SubcategoriaModel, toCategoriaModel: CategoriaModel) -> Bool {
        let mesReferencia = currentMonth.startOfMonth()
        let categoriaPlanejadaExistente: CategoriaPlanejadaModel?
        do {
            categoriaPlanejadaExistente = try repository.fetchCategoriaPlanejada(mes: mesReferencia, categoriaID: toCategoriaModel.id)
        } catch {
            CashUpLogger.persistence.error("Erro ao buscar CategoriaPlanejadaModel existente: \(error.localizedDescription, privacy: .public)")
            return false
        }

        guard let categoriaPlanejada = categoriaPlanejadaExistente else {
            CashUpLogger.persistence.error("Tentativa de adicionar subcategoria a uma CategoriaPlanejadaModel inexistente para o mês.")
            return false
        }

        if categoriaPlanejada.subcategoriasPlanejadas?.contains(where: { $0.subcategoriaOriginal?.id == subcategoriaModel.id }) == true {
            return false
        }

        let novaSubPlanejada = SubcategoriaPlanejadaModel(
            valorPlanejadoCentavos: 0,
            subcategoriaOriginal: subcategoriaModel,
            categoriaPlanejada: categoriaPlanejada
        )

        if categoriaPlanejada.subcategoriasPlanejadas == nil {
            categoriaPlanejada.subcategoriasPlanejadas = []
        }
        categoriaPlanejada.subcategoriasPlanejadas?.append(novaSubPlanejada)

        return salvarContexto(operacao: "adicionarSubcategoriaAoPlanejamento")
    }

    func adicionarNovaCategoriaAoPlanejamento(categoriaModel: CategoriaModel, comSubcategoriaInicial subcategoriaModel: SubcategoriaModel) -> Bool {
        let mesReferencia = currentMonth.startOfMonth()

        do {
            if try repository.fetchCategoriaPlanejada(mes: mesReferencia, categoriaID: categoriaModel.id) != nil {
                return adicionarSubcategoriaAoPlanejamento(subcategoriaModel: subcategoriaModel, toCategoriaModel: categoriaModel)
            }
        } catch {
            CashUpLogger.persistence.error("Erro ao verificar CategoriaPlanejadaModel existente: \(error.localizedDescription, privacy: .public)")
            return false
        }

        let novaCategoriaPlanejada = CategoriaPlanejadaModel(mesAno: mesReferencia, categoriaOriginal: categoriaModel)
        repository.insert(novaCategoriaPlanejada)

        let novaSubPlanejada = SubcategoriaPlanejadaModel(
            valorPlanejadoCentavos: 0,
            subcategoriaOriginal: subcategoriaModel,
            categoriaPlanejada: novaCategoriaPlanejada
        )

        novaCategoriaPlanejada.subcategoriasPlanejadas = [novaSubPlanejada]

        return salvarContexto(operacao: "adicionarNovaCategoriaAoPlanejamento")
    }

    func removerSubcategoriasPlanejadasSelecionadas(idsSubcategoriasPlanejadas: Set<UUID>) {
        guard !idsSubcategoriasPlanejadas.isEmpty else { return }

        var affectedParentCategorias = Set<CategoriaPlanejadaModel>()

        for id in idsSubcategoriasPlanejadas {
            do {
                guard let subParaDeletar = try repository.fetchSubcategoriaPlanejada(id: id) else { continue }
                if let parent = subParaDeletar.categoriaPlanejada {
                    affectedParentCategorias.insert(parent)
                    parent.subcategoriasPlanejadas?.removeAll { $0.id == id }
                }
                repository.delete(subParaDeletar)
            } catch {
                CashUpLogger.persistence.error("Erro ao buscar SubcategoriaPlanejadaModel (ID: \(id, privacy: .public)) para deleção: \(error.localizedDescription, privacy: .public)")
            }
        }

        for catPlan in affectedParentCategorias {
            let remainingSubcategories = catPlan.subcategoriasPlanejadas?.filter { subPlan in
                !idsSubcategoriasPlanejadas.contains(subPlan.id)
            }

            if remainingSubcategories?.isEmpty ?? true {
                repository.delete(catPlan)
            }
        }

        _ = salvarContexto(operacao: "removerSubcategoriasPlanejadasSelecionadas")
        objectWillChange.send()
    }

    func removerSubcategoriaPlanejada(id: UUID) {
        removerSubcategoriasPlanejadasSelecionadas(idsSubcategoriasPlanejadas: [id])
    }

    func zerarPlanejamentoDoMes() {
        let planejamentosDoMes = getCategoriasPlanejadasForCurrentMonth()
        if planejamentosDoMes.isEmpty { return }
        for planejamento in planejamentosDoMes {
            repository.delete(planejamento)
        }
        _ = salvarContexto(operacao: "zerarPlanejamentoDoMes")
    }

    func totalParaCategoriaPlanejada(_ categoriaPlanejada: CategoriaPlanejadaModel) -> Int64 {
        categoriaPlanejada.subcategoriasPlanejadas?.reduce(0) { $0 + $1.valorPlanejadoCentavos } ?? 0
    }

    func valorTotalPlanejadoParaMesAtual() -> Int64 {
        let categoriasDoMes = getCategoriasPlanejadasForCurrentMonth()
        return categoriasDoMes.reduce(0) { $0 + totalParaCategoriaPlanejada($1) }
    }

    func calcularPorcentagemTotal(paraCategoriaPlanejada categoria: CategoriaPlanejadaModel) -> Double {
        let totalCategoriaValue = totalParaCategoriaPlanejada(categoria)
        let totalPlanejadoMesValor = valorTotalPlanejadoParaMesAtual()
        return Centavos.razao(totalCategoriaValue, de: totalPlanejadoMesValor) * 100
    }

    func navigateMonth(isNext: Bool) {
        let calendar = Calendar.current
        if let newDate = calendar.date(byAdding: .month, value: isNext ? 1 : -1, to: currentMonth) {
            currentMonth = newDate.startOfMonth()
        }
    }

    func confirmCopyCurrentMonthPlanningToNextMonth() {
        let currentMonthStart = currentMonth.startOfMonth()
        guard let nextMonthDateUnsafe = Calendar.current.date(byAdding: .month, value: 1, to: currentMonthStart) else {
            self.copyResultAlertTitle = String(localized: "Erro")
            self.copyResultAlertMessage = String(localized: "Não foi possível determinar o próximo mês.")
            self.showCopyResultAlert = true
            return
        }
        let nextMonthStart = nextMonthDateUnsafe.startOfMonth()
        let currentLocale = Locale.autoupdatingCurrent

        let currentMonthFormatted = currentMonthStart.formatted(.dateTime.month(.wide).year().locale(currentLocale))
        let nextMonthFormatted = nextMonthStart.formatted(.dateTime.month(.wide).year().locale(currentLocale))

        let categoriasPlanejadasAtuais = getCategoriasPlanejadasForCurrentMonth()
        if categoriasPlanejadasAtuais.isEmpty {
            self.copyResultAlertTitle = String(localized: "Nenhum Planejamento")
            self.copyResultAlertMessage = String(localized: "Não há planejamento em \(currentMonthFormatted) para copiar.")
            self.showCopyResultAlert = true
            return
        }

        self.copyPlanningAlertTitle = String(localized: "Copiar Planejamento")
        self.copyPlanningAlertMessage = String(localized: "Deseja copiar o planejamento de \(currentMonthFormatted) para \(nextMonthFormatted)?")
        self.showCopyConfirmationAlert = true
    }

    func executeCopyPlanning() {
        let result = copyCurrentMonthPlanningToNextMonth()
        self.copyResultAlertTitle = result.title
        self.copyResultAlertMessage = result.message
        self.showCopyResultAlert = true
    }

    func copyCurrentMonthPlanningToNextMonth() -> (title: String, message: String) {
        let currentMonthStart = currentMonth.startOfMonth()
        guard let nextMonthDateUnsafe = Calendar.current.date(byAdding: .month, value: 1, to: currentMonthStart) else {
            return (String(localized: "Erro"), String(localized: "Não foi possível determinar o próximo mês."))
        }
        let nextMonthStart = nextMonthDateUnsafe.startOfMonth()
        let currentLocale = Locale.autoupdatingCurrent

        let categoriasPlanejadasAtuais: [CategoriaPlanejadaModel]
        do {
            categoriasPlanejadasAtuais = try repository.fetchCategoriasPlanejadas(mes: currentMonthStart)
        } catch {
            CashUpLogger.persistence.error("Erro ao buscar planejamento do mês atual: \(error.localizedDescription, privacy: .public)")
            return (String(localized: "Erro"), String(localized: "Falha ao buscar planejamento atual."))
        }

        if categoriasPlanejadasAtuais.isEmpty {
            return (String(localized: "Nenhum Planejamento"), String(localized: "Não há planejamento no mês atual para copiar."))
        }

        let categoriasPlanejadasProximoMesExistentes: [CategoriaPlanejadaModel]
        do {
            categoriasPlanejadasProximoMesExistentes = try repository.fetchCategoriasPlanejadas(mes: nextMonthStart)
        } catch {
            CashUpLogger.persistence.error("Erro ao buscar planejamento do próximo mês: \(error.localizedDescription, privacy: .public)")
            return (String(localized: "Erro"), String(localized: "Falha ao verificar planejamento existente no próximo mês."))
        }

        var countCopied = 0
        var countSkipped = 0
        var skippedCategoryNames: [String] = []

        for categoriaAtualPlanejada in categoriasPlanejadasAtuais {
            guard let categoriaOriginal = categoriaAtualPlanejada.categoriaOriginal else {
                CashUpLogger.persistence.error("Categoria planejada \(categoriaAtualPlanejada.id, privacy: .public) sem categoria original.")
                continue
            }

            if categoriasPlanejadasProximoMesExistentes.contains(where: { $0.categoriaOriginal?.id == categoriaOriginal.id }) {
                countSkipped += 1
                skippedCategoryNames.append(categoriaOriginal.nome)
                continue
            }

            let novaCategoriaPlanejadaProximoMes = CategoriaPlanejadaModel(
                mesAno: nextMonthStart,
                categoriaOriginal: categoriaOriginal
            )
            repository.insert(novaCategoriaPlanejadaProximoMes)

            var novasSubcategoriasPlanejadas: [SubcategoriaPlanejadaModel] = []
            if let subcategoriasAtuais = categoriaAtualPlanejada.subcategoriasPlanejadas {
                for subAtualPlanejada in subcategoriasAtuais {
                    guard let subcategoriaOriginal = subAtualPlanejada.subcategoriaOriginal else {
                        CashUpLogger.persistence.error("Subcategoria planejada \(subAtualPlanejada.id, privacy: .public) sem subcategoria original.")
                        continue
                    }
                    let novaSubcategoriaProximoMes = SubcategoriaPlanejadaModel(
                        valorPlanejadoCentavos: subAtualPlanejada.valorPlanejadoCentavos,
                        subcategoriaOriginal: subcategoriaOriginal,
                        categoriaPlanejada: novaCategoriaPlanejadaProximoMes
                    )
                    novasSubcategoriasPlanejadas.append(novaSubcategoriaProximoMes)
                }
            }
            novaCategoriaPlanejadaProximoMes.subcategoriasPlanejadas = novasSubcategoriasPlanejadas
            countCopied += 1
        }

        let proximoMesFormatado = nextMonthStart.formatted(.dateTime.month(.wide).year().locale(currentLocale))

        if countCopied == 0 && countSkipped == 0 && !categoriasPlanejadasAtuais.isEmpty {
            return (String(localized: "Nenhuma Ação"), String(localized: "Nenhuma categoria válida foi encontrada para copiar (verifique se possuem categorias originais associadas)."))
        }
        if countCopied == 0 && countSkipped > 0 {
            let nomesPulados = skippedCategoryNames.joined(separator: ", ")
            return (
                String(localized: "Nenhuma Categoria Copiada"),
                String(localized: "\(countSkipped) categoria(s) (\(nomesPulados)) já existia(m) em \(proximoMesFormatado) e foi(ram) pulada(s). Nenhuma nova categoria foi copiada.")
            )
        }

        do {
            try repository.save()
            objectWillChange.send()

            let title = String(localized: "Sucesso")
            var message = ""
            let nomesPulados = skippedCategoryNames.joined(separator: ", ")

            if countCopied > 0 && countSkipped > 0 {
                let copiadas = String(localized: "\(countCopied) categoria(s) copiada(s) para \(proximoMesFormatado).")
                let puladas = String(localized: "\(countSkipped) categoria(s) (\(nomesPulados)) pulada(s) pois já existiam.")
                message = copiadas + "\n" + puladas
            } else if countCopied > 0 {
                message = String(localized: "\(countCopied) categoria(s) planejada(s) copiada(s) com sucesso para \(proximoMesFormatado).")
            }

            return (title, message.isEmpty ? String(localized: "Nenhuma ação de cópia necessitou ser realizada.") : message)
        } catch {
            CashUpLogger.persistence.error("Erro ao salvar o planejamento copiado: \(error.localizedDescription, privacy: .public)")
            return (String(localized: "Erro"), String(localized: "Falha ao salvar o planejamento copiado: \(error.localizedDescription)"))
        }
    }
}
