import Combine
import Foundation
import SwiftData
import SwiftUI

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
        (try? repository.fetchCategoriasPlanejadas(mes: currentMonth)) ?? []
    }

    private func salvarContexto(operacao: String = "Operação Desconhecida") -> Bool {
        do {
            try repository.save()
            objectWillChange.send()
            return true
        } catch {
            CashUpLogger.persistence.error("Erro ao salvar contexto após \(operacao, privacy: .public): \(error.localizedDescription, privacy: .public)")
            return false
        }
    }

    func adicionarSubcategoriaAoPlanejamento(subcategoriaModel: SubcategoriaModel, toCategoriaModel: CategoriaModel) -> Bool {
        let mesReferencia = currentMonth.startOfMonth()
        guard let categoriaPlanejada = try? repository.fetchCategoriaPlanejada(mes: mesReferencia, categoriaID: toCategoriaModel.id) else {
            CashUpLogger.persistence.error("Tentativa de adicionar subcategoria a uma CategoriaPlanejadaModel inexistente para o mês.")
            return false
        }

        if categoriaPlanejada.subcategoriasPlanejadas?.contains(where: { $0.subcategoriaOriginal?.id == subcategoriaModel.id }) == true {
            return false
        }

        let novaSubPlanejada = SubcategoriaPlanejadaModel(
            valorPlanejado: 0.0,
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

        if (try? repository.fetchCategoriaPlanejada(mes: mesReferencia, categoriaID: categoriaModel.id)) != nil {
            return adicionarSubcategoriaAoPlanejamento(subcategoriaModel: subcategoriaModel, toCategoriaModel: categoriaModel)
        }

        let novaCategoriaPlanejada = CategoriaPlanejadaModel(mesAno: mesReferencia, categoriaOriginal: categoriaModel)
        try? repository.insert(novaCategoriaPlanejada)

        let novaSubPlanejada = SubcategoriaPlanejadaModel(
            valorPlanejado: 0.0,
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
            if let subParaDeletar = try? repository.fetchSubcategoriaPlanejada(id: id) {
                if let parent = subParaDeletar.categoriaPlanejada {
                    affectedParentCategorias.insert(parent)
                }
                try? repository.delete(subParaDeletar)
            }
        }

        for catPlan in affectedParentCategorias {
            let remainingSubcategories = catPlan.subcategoriasPlanejadas?.filter { subPlan in
                !idsSubcategoriasPlanejadas.contains(subPlan.id)
            }

            if remainingSubcategories?.isEmpty ?? true {
                try? repository.delete(catPlan)
            }
        }

        _ = salvarContexto(operacao: "removerSubcategoriasPlanejadasSelecionadas")
    }

    func zerarPlanejamentoDoMes() {
        let planejamentosDoMes = getCategoriasPlanejadasForCurrentMonth()
        if planejamentosDoMes.isEmpty { return }
        for planejamento in planejamentosDoMes {
            try? repository.delete(planejamento)
        }
        _ = salvarContexto(operacao: "zerarPlanejamentoDoMes")
    }

    func totalParaCategoriaPlanejada(_ categoriaPlanejada: CategoriaPlanejadaModel) -> Double {
        categoriaPlanejada.subcategoriasPlanejadas?.reduce(0) { $0 + $1.valorPlanejado } ?? 0.0
    }

    func valorTotalPlanejadoParaMesAtual() -> Double {
        let categoriasDoMes = getCategoriasPlanejadasForCurrentMonth()
        return categoriasDoMes.reduce(0) { $0 + totalParaCategoriaPlanejada($1) }
    }

    func calcularPorcentagemTotal(paraCategoriaPlanejada categoria: CategoriaPlanejadaModel) -> Double {
        let totalCategoriaValue = totalParaCategoriaPlanejada(categoria)
        let totalPlanejadoMesValor = valorTotalPlanejadoParaMesAtual()
        guard totalPlanejadoMesValor > 0 else { return 0 }
        return (totalCategoriaValue / totalPlanejadoMesValor) * 100
    }

    func bindingParaValorPlanejado(subItem: SubcategoriaPlanejadaModel) -> Binding<String> {
        Binding<String>(
            get: {
                let formatter = NumberFormatter()
                formatter.numberStyle = .decimal
                formatter.maximumFractionDigits = 2
                formatter.minimumFractionDigits = 2
                formatter.locale = Locale(identifier: "pt_BR")
                return formatter.string(from: NSNumber(value: subItem.valorPlanejado)) ?? "0,00"
            },
            set: { [self] novoValorString in
                let formatter = NumberFormatter()
                formatter.numberStyle = .decimal
                formatter.locale = Locale(identifier: "pt_BR")

                if let numero = formatter.number(from: novoValorString) {
                    subItem.valorPlanejado = numero.doubleValue
                } else {
                    let cleanedString = novoValorString.replacingOccurrences(of: ",", with: ".")
                    if let doubleValue = Double(cleanedString) {
                        subItem.valorPlanejado = doubleValue
                    }
                }
                objectWillChange.send()
            }
        )
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
            self.copyResultAlertTitle = "Erro"
            self.copyResultAlertMessage = "Não foi possível determinar o próximo mês."
            self.showCopyResultAlert = true
            return
        }
        let nextMonthStart = nextMonthDateUnsafe.startOfMonth()
        let ptBRLocale = Locale(identifier: "pt_BR")

        let currentMonthFormatted = currentMonthStart.formatted(.dateTime.month(.wide).year().locale(ptBRLocale))
        let nextMonthFormatted = nextMonthStart.formatted(.dateTime.month(.wide).year().locale(ptBRLocale))

        let categoriasPlanejadasAtuais = getCategoriasPlanejadasForCurrentMonth()
        if categoriasPlanejadasAtuais.isEmpty {
            self.copyResultAlertTitle = "Nenhum Planejamento"
            self.copyResultAlertMessage = "Não há planejamento em \(currentMonthFormatted) para copiar."
            self.showCopyResultAlert = true
            return
        }

        self.copyPlanningAlertTitle = "Copiar Planejamento"
        self.copyPlanningAlertMessage = "Deseja copiar o planejamento de \(currentMonthFormatted) para \(nextMonthFormatted)?"
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
            return ("Erro", "Não foi possível determinar o próximo mês.")
        }
        let nextMonthStart = nextMonthDateUnsafe.startOfMonth()
        let ptBRLocale = Locale(identifier: "pt_BR")

        let categoriasPlanejadasAtuais = (try? repository.fetchCategoriasPlanejadas(mes: currentMonthStart)) ?? []
        if categoriasPlanejadasAtuais.isEmpty {
            return ("Nenhum Planejamento", "Não há planejamento no mês atual para copiar.")
        }

        let categoriasPlanejadasProximoMesExistentes = (try? repository.fetchCategoriasPlanejadas(mes: nextMonthStart)) ?? []

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
            try? repository.insert(novaCategoriaPlanejadaProximoMes)

            var novasSubcategoriasPlanejadas: [SubcategoriaPlanejadaModel] = []
            if let subcategoriasAtuais = categoriaAtualPlanejada.subcategoriasPlanejadas {
                for subAtualPlanejada in subcategoriasAtuais {
                    guard let subcategoriaOriginal = subAtualPlanejada.subcategoriaOriginal else {
                        CashUpLogger.persistence.error("Subcategoria planejada \(subAtualPlanejada.id, privacy: .public) sem subcategoria original.")
                        continue
                    }
                    let novaSubcategoriaProximoMes = SubcategoriaPlanejadaModel(
                        valorPlanejado: subAtualPlanejada.valorPlanejado,
                        subcategoriaOriginal: subcategoriaOriginal,
                        categoriaPlanejada: novaCategoriaPlanejadaProximoMes
                    )
                    novasSubcategoriasPlanejadas.append(novaSubcategoriaProximoMes)
                }
            }
            novaCategoriaPlanejadaProximoMes.subcategoriasPlanejadas = novasSubcategoriasPlanejadas
            countCopied += 1
        }

        let proximoMesFormatado = nextMonthStart.formatted(.dateTime.month(.wide).year().locale(ptBRLocale))

        if countCopied == 0 && countSkipped == 0 && !categoriasPlanejadasAtuais.isEmpty {
            return ("Nenhuma Ação", "Nenhuma categoria válida foi encontrada para copiar (verifique se possuem categorias originais associadas).")
        }
        if countCopied == 0 && countSkipped > 0 {
            return ("Nenhuma Categoria Copiada", "\(countSkipped) categoria(s) (\(skippedCategoryNames.joined(separator: ", "))) já existia(m) em \(proximoMesFormatado) e foi(ram) pulada(s). Nenhuma nova categoria foi copiada.")
        }

        do {
            try repository.save()
            objectWillChange.send()

            let title = "Sucesso"
            var message = ""

            if countCopied > 0 && countSkipped > 0 {
                message = "\(countCopied) categoria(s) copiada(s) para \(proximoMesFormatado).\n\(countSkipped) categoria(s) (\(skippedCategoryNames.joined(separator: ", "))) pulada(s) pois já existiam."
            } else if countCopied > 0 {
                message = "\(countCopied) categoria(s) planejada(s) copiada(s) com sucesso para \(proximoMesFormatado)."
            }

            return (title, message.isEmpty ? "Nenhuma ação de cópia necessitou ser realizada." : message)
        } catch {
            CashUpLogger.persistence.error("Erro ao salvar o planejamento copiado: \(error.localizedDescription, privacy: .public)")
            return ("Erro", "Falha ao salvar o planejamento copiado: \(error.localizedDescription)")
        }
    }
}
