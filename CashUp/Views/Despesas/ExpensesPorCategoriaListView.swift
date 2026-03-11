//
//  ExpensesPorCategoriaListView.swift
//  CashUp
//
//  Created by Gustavo Souto Pereira on 19/05/25.
//

import SwiftUI
import SwiftData
import Charts

struct SubcategoryDetailSheetDataSwiftData: Identifiable {
    let id: UUID
    let subcategoriaModel: SubcategoriaModel
    let isIncome: Bool
    
    init(subcategoriaModel: SubcategoriaModel, isIncome: Bool) {
        self.id = subcategoriaModel.id
        self.subcategoriaModel = subcategoriaModel
        self.isIncome = isIncome
    }
}

struct ExpensesPorCategoriaListView: View {
    @ObservedObject var viewModel: ExpensesViewModel
    
    @State private var localSelectedTransactionType: Int
    @State private var expandedCategories: Set<UUID> = []
    @State private var selectedSubcategoryDataForSheet: SubcategoryDetailSheetDataSwiftData? = nil
    
    @State private var highlightedCategoryID: UUID? = nil
    @State private var rawSelectedChartItem: ChartCategoriasData? = nil
    
    init(viewModel: ExpensesViewModel) {
        self.viewModel = viewModel
        self._localSelectedTransactionType = State(initialValue: viewModel.selectedTransactionType)
    }
    
    struct ChartCategoriasData: Identifiable, Hashable {
        let id: UUID
        let categoria: CategoriaModel
        let total: Double
        let color: Color
        let nome: String
        let icon: String
        
        init(categoria: CategoriaModel, total: Double) {
            self.id = categoria.id
            self.categoria = categoria
            self.total = total
            self.color = categoria.color
            self.nome = categoria.nome
            self.icon = categoria.icon
        }
        
        static func == (lhs: ChartCategoriasData, rhs: ChartCategoriasData) -> Bool {
            lhs.id == rhs.id
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
    }
    
    private var dataParaGrafico: [ChartCategoriasData] {
        let transacoes = transacoesRelevantesParaCalculo
        let groupedByCategoria = Dictionary(grouping: transacoes, by: { $0.categoria })
        
        return groupedByCategoria.compactMap { (categoriaOpt, transacoesCategoria) in
            guard let categoria = categoriaOpt, !transacoesCategoria.isEmpty else { return nil }
            let totalCategoria = transacoesCategoria.reduce(0) { $0 + $1.amount }
            guard totalCategoria > 0 else { return nil } 
            return ChartCategoriasData(categoria: categoria, total: totalCategoria)
        }.sorted { itemA, itemB in
            if abs(itemA.total - itemB.total) > 0.001 {
                return itemA.total > itemB.total
            } else {
                return itemA.nome.localizedCompare(itemB.nome) == .orderedAscending
            }
        }
    }
    
    private var categoriasParaLista: [CategoriaModel] {
        let todasCategoriasComTransacoes = transacoesRelevantesParaCalculo.compactMap { $0.categoria }
        let categoriasUnicas = Dictionary(grouping: todasCategoriasComTransacoes, by: { $0.id })
            .values.compactMap { $0.first }
        
        return categoriasUnicas.sorted { catA, catB in
            let totalA = totalParaCategoria(catA)
            let totalB = totalParaCategoria(catB)
            
            if abs(totalA - totalB) > 0.001 {
                return totalA > totalB
            } else {
                return catA.nome.localizedCompare(catB.nome) == .orderedAscending
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            TransactionPicker(selectedTransactionType: $localSelectedTransactionType)
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 12)
                .onChange(of: localSelectedTransactionType) { _, newValue in
                    viewModel.selectedTransactionType = newValue
                    clearAllSelections()
                }
            
            if !dataParaGrafico.isEmpty {
                ZStack {
                    Chart(dataParaGrafico) { dataItem in
                        SectorMark(
                            angle: .value("Total", dataItem.total),
                            innerRadius: .ratio(0.70),
                            outerRadius: highlightedCategoryID == dataItem.id ? .ratio(1.0) : .ratio(0.96),
                            angularInset: 1.5
                        )
                        .foregroundStyle(dataItem.color)
                        .cornerRadius(6)
                        .opacity(highlightedCategoryID == nil || highlightedCategoryID == dataItem.id ? 1.0 : 0.3)
                        .accessibilityLabel(dataItem.nome)
                        .accessibilityValue(formatCurrency(dataItem.total))
                    }
                    .frame(height: 160)
                    .padding(.vertical, 5)
                    .onChange(of: rawSelectedChartItem) { _, newValue in
                        withAnimation(.snappy) {
                            let newCatID = newValue?.id
                            if highlightedCategoryID == newCatID {
                                highlightedCategoryID = newCatID
                                if let id = newCatID {
                                    expandedCategories = [id]
                                } else if newValue == nil {
                                    expandedCategories.removeAll()
                                    highlightedCategoryID = nil
                                }
                            } else { // Nova seleção no gráfico
                                highlightedCategoryID = newCatID
                                if let id = newCatID {
                                    expandedCategories = [id]
                                } else {
                                    expandedCategories.removeAll()
                                    highlightedCategoryID = nil
                                }
                            }
                        }
                    }
                    
                    if let categoryID = highlightedCategoryID,
                       let highlightedData = dataParaGrafico.first(where: { $0.id == categoryID }) {
                        VStack(spacing: 2) {
                            Image(systemName: highlightedData.icon)
                                .font(.system(size: 28))
                                .foregroundColor(highlightedData.color)
                            Text(highlightedData.nome)
                                .font(.callout.bold())
                                .lineLimit(1)
                                .minimumScaleFactor(0.5)
                            Text(formatCurrency(highlightedData.total))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(width: 100)
                    } else {
                        VStack {
                            Text(localSelectedTransactionType == 0 ? "Total Gasto" : "Total Recebido")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(formatCurrency(dataParaGrafico.reduce(0, { $0 + $1.total })))
                                .font(.title3.bold())
                                .foregroundColor(.primary)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 5)
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.snappy) {
                        clearAllSelections()
                    }
                }
                
            } else {
                VStack {
                    Spacer()
                    
                    Image(systemName: "chart.pie.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(Color.secondary.opacity(0.5))
                        .padding(.bottom, 8)
                    Text(viewModel.selectedTransactionType == 0 ? "Nenhuma despesa neste mês" : "Nenhuma receita neste mês")
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .frame(height: 180)
            }
            
            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(categoriasParaLista, id: \.id) { categoriaModel in
                        categoriaSectionView(categoriaModel: categoriaModel)
                    }
                }
                .padding(.bottom)
            }
        }
        .sheet(item: $selectedSubcategoryDataForSheet) { data in
            SubcategoryDetailView(
                subcategoriaModel: data.subcategoriaModel,
                isIncome: data.isIncome,
                viewModel: viewModel
            )
            .environment(\.modelContext, viewModel.modelContext)
        }
        .onAppear {
            if localSelectedTransactionType != viewModel.selectedTransactionType {
                localSelectedTransactionType = viewModel.selectedTransactionType
            }
        }
    }
    
    @ViewBuilder
    private func categoriaSectionView(categoriaModel: CategoriaModel) -> some View {
        VStack(spacing: 0) {
            HStack {
                Rectangle()
                    .fill(categoriaModel.color)
                    .frame(width: 5, height: 22)
                    .cornerRadius(2.5)
                Text(categoriaModel.nome)
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                Spacer()
                Text(formatCurrency(totalParaCategoria(categoriaModel)))
                    .font(.callout)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                Image(systemName: expandedCategories.contains(categoriaModel.id) ? "chevron.down" : "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(Color(.secondarySystemBackground))
            .contentShape(Rectangle())
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("CategoryRow_\(categoriaModel.nome)")
            .accessibilityLabel("\(categoriaModel.nome), \(formatCurrency(totalParaCategoria(categoriaModel)))")
            .onTapGesture {
                withAnimation(.snappy) {
                    let categoriaID = categoriaModel.id
                    if highlightedCategoryID == categoriaID {
                        highlightedCategoryID = nil
                        rawSelectedChartItem = nil
                        expandedCategories.remove(categoriaID)
                    } else {
                        highlightedCategoryID = categoriaID
                        rawSelectedChartItem = dataParaGrafico.first(where: { $0.id == categoriaID })
                        expandedCategories = [categoriaID]
                    }
                }
            }
            
            if expandedCategories.contains(categoriaModel.id) {
                VStack(spacing: 0) { // VStack para as subcategorias
                    ForEach(subcategoriasParaCategoria(categoriaModel), id: \.id) { subModel in
                        Button {
                            selectedSubcategoryDataForSheet = SubcategoryDetailSheetDataSwiftData(
                                subcategoriaModel: subModel,
                                isIncome: localSelectedTransactionType == 1
                            )
                        } label: {
                            HStack {
                                Circle()
                                    .fill(categoriaModel.color.opacity(0.7))
                                    .frame(width: 8, height: 8)
                                    .padding(.leading, 8)
                                Text(subModel.nome)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                    .accessibilityIdentifier("SubcategoryRow_\(subModel.nome)")
                                Spacer()
                                Text(formatCurrency(totalParaSubcategoria(subModel)))
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(Color.gray.opacity(0.5))
                                    .font(.system(size: 10, weight: .bold))
                            }
                            .padding(.leading)
                            .padding(.trailing)
                            .padding(.vertical, 10)
                            .background(Color(.secondarySystemBackground))
                        }
                        .buttonStyle(.plain)
                        if subModel.id != subcategoriasParaCategoria(categoriaModel).last?.id {
                            Divider().padding(.leading, 35)
                        }
                    }
                }
                .background(Color(.secondarySystemBackground))
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal)
    }
    
    private var transacoesRelevantesParaCalculo: [DisplayableExpense] {
        viewModel.transacoesExibidas
    }
    
    private func clearAllSelections() {
        rawSelectedChartItem = nil
        highlightedCategoryID = nil
        expandedCategories.removeAll()
    }
    
    func subcategoriasParaCategoria(_ categoriaModel: CategoriaModel) -> [SubcategoriaModel] {
        let transacoesDaCategoria = transacoesRelevantesParaCalculo.filter { $0.categoria?.id == categoriaModel.id }
        let subcategorias = transacoesDaCategoria.compactMap { $0.subcategoria }
        let subcategoriasUnicas = Dictionary(grouping: subcategorias, by: { $0.id })
            .values.compactMap { $0.first }
        
        return Array(subcategoriasUnicas).sorted {
            totalParaSubcategoria($0) > totalParaSubcategoria($1)
        }
    }
    
    func totalParaCategoria(_ categoriaModel: CategoriaModel) -> Double {
        transacoesRelevantesParaCalculo
            .filter { $0.categoria?.id == categoriaModel.id }
            .reduce(0.0) { $0 + $1.amount }
    }
    
    func totalParaSubcategoria(_ subModel: SubcategoriaModel) -> Double {
        transacoesRelevantesParaCalculo
            .filter { $0.subcategoria?.id == subModel.id }
            .reduce(0.0) { $0 + $1.amount }
    }
    
    func toggleCategory(_ id: UUID) {
        if expandedCategories.contains(id) {
            expandedCategories.remove(id)
        } else {
            expandedCategories = [id]
        }
    }
}
