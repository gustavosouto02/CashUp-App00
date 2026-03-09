//
//  PlanningViewModel.swift
//  CashUp
//
//  Created by Gustavo Souto Pereira on 19/05/25.
//

import SwiftUI
import Foundation
import Combine
import SwiftData

@MainActor
class PlanningViewModel: ObservableObject {

    var modelContext: ModelContext

    @Published var selectedTab: Int = 0
    @Published var currentMonth: Date {
        didSet {
            if oldValue.startOfMonth() != currentMonth.startOfMonth() {
                objectWillChange.send()
            }
        }
    }

    @Published var copyPlanningAlertTitle: String = ""
    @Published var copyPlanningAlertMessage: String = ""
    @Published var showCopyConfirmationAlert: Bool = false
    @Published var showCopyResultAlert: Bool = false
    @Published var copyResultAlertTitle: String = ""
    @Published var copyResultAlertMessage: String = ""

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        let now = Date()
        _currentMonth = Published(initialValue: now.startOfMonth())
    }

    // MARK: - Gerenciamento de Categorias e Subcategorias Planejadas

    func getCategoriasPlanejadasForCurrentMonth() -> [CategoriaPlanejadaModel] {
        let monthToFetch = currentMonth.startOfMonth()
        let predicate = #Predicate<CategoriaPlanejadaModel> {
            $0.mesAno == monthToFetch
        }
        let fetchDescriptor = FetchDescriptor<CategoriaPlanejadaModel>(predicate: predicate)
        do {
            let categorias = try modelContext.fetch(fetchDescriptor)
            return categorias.sorted { ($0.categoriaOriginal?.nome ?? "") < ($1.categoriaOriginal?.nome ?? "") }
        } catch {
            print("Erro ao buscar CategoriaPlanejadaModel para o mês: \(error)")
            return []
        }
    }
    private func salvarContexto(operacao: String = "Operação Desconhecida") -> Bool {
        do {
            try modelContext.save()
            print("Contexto salvo com sucesso após: \(operacao)")
            objectWillChange.send()
            return true
        } catch {
            print("Erro ao salvar contexto após \(operacao): \(error)")
            return false
        }
    }

    func adicionarSubcategoriaAoPlanejamento(subcategoriaModel: SubcategoriaModel,
                                            toCategoriaModel: CategoriaModel) -> Bool {
        let mesReferencia = currentMonth.startOfMonth()
        let targetCategoriaID = toCategoriaModel.id

        let predicateExistingCatPlan = #Predicate<CategoriaPlanejadaModel> { catPlan in
            catPlan.mesAno == mesReferencia &&
            (catPlan.categoriaOriginal.flatMap { $0.id } == targetCategoriaID)
        }
        let fetchDescriptorCatPlan = FetchDescriptor(predicate: predicateExistingCatPlan)
        
        var categoriaPlanejadaExistente: CategoriaPlanejadaModel?
        do {
            categoriaPlanejadaExistente = try modelContext.fetch(fetchDescriptorCatPlan).first
        } catch {
            print("Erro ao buscar CategoriaPlanejadaModel existente: \(error)")
            return false
        }

        guard let categoriaPlanejada = categoriaPlanejadaExistente else {
            print("Erro lógico: Tentando adicionar subcategoria a uma CategoriaPlanejadaModel que não existe para o mês e categoria. Use adicionarNovaCategoriaAoPlanejamento ou crie a CategoriaPlanejada primeiro.")
            return false
        }

        if categoriaPlanejada.subcategoriasPlanejadas?.contains(where: { $0.subcategoriaOriginal?.id == subcategoriaModel.id }) == true {
            print("Subcategoria '\(subcategoriaModel.nome)' já existe no planejamento para '\(categoriaPlanejada.nomeCategoriaOriginal)' este mês.")
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
        
        print("Subcategoria '\(subcategoriaModel.nome)' adicionada ao planejamento de '\(categoriaPlanejada.nomeCategoriaOriginal)'.")
        return salvarContexto(operacao: "adicionarSubcategoriaAoPlanejamento")
    }
    
    func adicionarNovaCategoriaAoPlanejamento(categoriaModel: CategoriaModel,
                                            comSubcategoriaInicial subcategoriaModel: SubcategoriaModel) -> Bool {
        let mesReferencia = currentMonth.startOfMonth()
        let targetCategoriaID = categoriaModel.id

        let predicateExistingCatPlan = #Predicate<CategoriaPlanejadaModel> { catPlan in
            catPlan.mesAno == mesReferencia &&
            (catPlan.categoriaOriginal.flatMap { $0.id } == targetCategoriaID)
        }
        let fetchDescriptorCatPlan = FetchDescriptor(predicate: predicateExistingCatPlan)
        
        do {
            if (try modelContext.fetch(fetchDescriptorCatPlan).first) != nil {
                print("Categoria '\(categoriaModel.nome)' já possui um planejamento. Adicionando subcategoria '\(subcategoriaModel.nome)' ao planejamento existente.")
                return adicionarSubcategoriaAoPlanejamento(subcategoriaModel: subcategoriaModel, toCategoriaModel: categoriaModel)
            }
        } catch {
            print("Erro ao verificar CategoriaPlanejadaModel existente: \(error)")
            return false
        }
        
        let novaCategoriaPlanejada = CategoriaPlanejadaModel(mesAno: mesReferencia, categoriaOriginal: categoriaModel)
        modelContext.insert(novaCategoriaPlanejada)

        let novaSubPlanejada = SubcategoriaPlanejadaModel(
            valorPlanejado: 0.0,
            subcategoriaOriginal: subcategoriaModel,
            categoriaPlanejada: novaCategoriaPlanejada
        )

        novaCategoriaPlanejada.subcategoriasPlanejadas = [novaSubPlanejada]
        
        print("Nova categoria '\(categoriaModel.nome)' com subcategoria inicial '\(subcategoriaModel.nome)' adicionada ao planejamento.")
        return salvarContexto(operacao: "adicionarNovaCategoriaAoPlanejamento")
    }

    func removerSubcategoriasPlanejadasSelecionadas(idsSubcategoriasPlanejadas: Set<UUID>) {
        guard !idsSubcategoriasPlanejadas.isEmpty else {
            print("Nenhuma subcategoria selecionada para deleção.")
            return
        }

        var affectedParentCategorias = Set<CategoriaPlanejadaModel>()

        for id in idsSubcategoriasPlanejadas {
            let predicate = #Predicate<SubcategoriaPlanejadaModel> { $0.id == id }
            var fetchDescriptor = FetchDescriptor<SubcategoriaPlanejadaModel>(predicate: predicate)
            fetchDescriptor.fetchLimit = 1
            
            do {
                if let subParaDeletar = try modelContext.fetch(fetchDescriptor).first {
                    if let parent = subParaDeletar.categoriaPlanejada {
                        affectedParentCategorias.insert(parent)
                    }
                    modelContext.delete(subParaDeletar)
                    print("SubcategoriaPlanejadaModel com ID \(id) marcada para deleção.")
                }
            } catch {
                print("Erro ao buscar SubcategoriaPlanejadaModel (ID: \(id)) para deleção: \(error)")
            }
        }
        
        for catPlan in affectedParentCategorias {
            let remainingSubcategories = catPlan.subcategoriasPlanejadas?.filter { subPlan in
                !idsSubcategoriasPlanejadas.contains(subPlan.id)
            }

            if remainingSubcategories?.isEmpty ?? true {
                print("CategoriaPlanejadaModel '\(catPlan.nomeCategoriaOriginal)' ficou vazia e será deletada.")
                modelContext.delete(catPlan)
            }
        }

        _ = salvarContexto(operacao: "removerSubcategoriasPlanejadasSelecionadas")
    }
    
    func zerarPlanejamentoDoMes() {
        let planejamentosDoMes = getCategoriasPlanejadasForCurrentMonth()
        if planejamentosDoMes.isEmpty {
            print("Nenhum planejamento para zerar neste mês.")
            return
        }
        for planejamento in planejamentosDoMes {
            modelContext.delete(planejamento)
        }
        print("Todos os planejamentos para o mês \(currentMonth.formatted(.dateTime.month(.wide).year())) foram marcados para deleção.")
        _ = salvarContexto(operacao: "zerarPlanejamentoDoMes")
    }

    // MARK: - Cálculos
    func totalParaCategoriaPlanejada(_ categoriaPlanejada: CategoriaPlanejadaModel) -> Double {
        return categoriaPlanejada.subcategoriasPlanejadas?.reduce(0) { $0 + $1.valorPlanejado } ?? 0.0
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
                    } else {

                        print("Input inválido para valor planejado: \(novoValorString)")
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

        let currentMonthPredicate = #Predicate<CategoriaPlanejadaModel> { $0.mesAno == currentMonthStart }
        let currentMonthFetchDescriptor = FetchDescriptor(predicate: currentMonthPredicate)
        let categoriasPlanejadasAtuais: [CategoriaPlanejadaModel]
        do {
            categoriasPlanejadasAtuais = try modelContext.fetch(currentMonthFetchDescriptor)
        } catch {
            print("Erro ao buscar planejamento do mês atual: \(error)")
            return ("Erro", "Falha ao buscar planejamento atual.")
        }

        if categoriasPlanejadasAtuais.isEmpty {
            return ("Nenhum Planejamento", "Não há planejamento no mês atual para copiar.")
        }

        let nextMonthPredicate = #Predicate<CategoriaPlanejadaModel> { $0.mesAno == nextMonthStart }
        let nextMonthFetchDescriptor = FetchDescriptor(predicate: nextMonthPredicate)
        let categoriasPlanejadasProximoMesExistentes: [CategoriaPlanejadaModel]
        do {
            categoriasPlanejadasProximoMesExistentes = try modelContext.fetch(nextMonthFetchDescriptor)
        } catch {
            print("Erro ao buscar planejamento do próximo mês: \(error)")
            return ("Erro", "Falha ao verificar planejamento existente no próximo mês.")
        }

        var countCopied = 0
        var countSkipped = 0
        var skippedCategoryNames: [String] = []

        for categoriaAtualPlanejada in categoriasPlanejadasAtuais {
            guard let categoriaOriginal = categoriaAtualPlanejada.categoriaOriginal else {
                print("Aviso: Categoria planejada atual (ID: \(categoriaAtualPlanejada.id)) sem categoria original. Pulando.")
                continue
            }

            if categoriasPlanejadasProximoMesExistentes.contains(where: { $0.categoriaOriginal?.id == categoriaOriginal.id }) {
                print("Planejamento para '\(categoriaOriginal.nome)' já existe no próximo mês. Pulando.")
                countSkipped += 1
                skippedCategoryNames.append(categoriaOriginal.nome)
                continue
            }

            let novaCategoriaPlanejadaProximoMes = CategoriaPlanejadaModel(
                mesAno: nextMonthStart,
                categoriaOriginal: categoriaOriginal
            )
            modelContext.insert(novaCategoriaPlanejadaProximoMes)

            var novasSubcategoriasPlanejadas: [SubcategoriaPlanejadaModel] = []
            if let subcategoriasAtuais = categoriaAtualPlanejada.subcategoriasPlanejadas {
                for subAtualPlanejada in subcategoriasAtuais {
                    guard let subcategoriaOriginal = subAtualPlanejada.subcategoriaOriginal else {
                        print("Aviso: Subcategoria planejada (ID: \(subAtualPlanejada.id)) sem subcategoria original. Pulando.")
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
            try modelContext.save()
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
            print("Erro ao salvar o planejamento copiado: \(error.localizedDescription)")
            return ("Erro", "Falha ao salvar o planejamento copiado: \(error.localizedDescription)")
        }
    }
}
