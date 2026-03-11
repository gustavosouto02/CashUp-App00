//
//  HomeView.swift
//  CashUp
//
//  Created by Gustavo Souto Pereira on 19/05/25.
//



import SwiftUI
import SwiftData
import Charts

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.sizeCategory) var sizeCategory
    
    @StateObject private var homeViewModel: HomeViewModel
    @StateObject private var expensesViewModel: ExpensesViewModel
    
    @State private var isAddTransactionPresented = false
    @State private var isTipsPresented = false
    
    init(modelContext: ModelContext) {
        let planningVM = PlanningViewModel(modelContext: modelContext)
        let expensesVM = ExpensesViewModel(modelContext: modelContext)
        let homeVM = HomeViewModel(
            modelContext: modelContext,
            planningViewModel: planningVM,
            expensesViewModel: expensesVM
        )
        _homeViewModel = StateObject(wrappedValue: homeVM)
        _expensesViewModel = StateObject(wrappedValue: expensesVM)
    }
    
    var body: some View {
        let _ = Self._printChanges()
        
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    
                    MonthSelector(
                        viewModel: MonthSelectorViewModel(selectedMonth: homeViewModel.currentMonth),
                        onMonthChanged: { selectedDate in
                            homeViewModel.currentMonth = selectedDate.startOfMonth()
                        }
                    )
                    .padding(.horizontal)
                    
                    miniChartCard
                        .padding(.horizontal)
                    
                    planningCard
                        .padding(.horizontal)
                    
                    expensesSummaryCombinedCard
                        .padding(.horizontal)
                    
                    Spacer(minLength: 24)
                }
                .padding(.top)
            }
            .navigationTitle("Visão Geral")
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button {
                        isTipsPresented = true
                    } label: {
                        Image(systemName: "info.circle.fill")
                            .font(.headline)
                    }
                    
                    Button {
                        isAddTransactionPresented = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "plus.circle.fill")
                            Text("Registrar")
                        }
                        .font(.headline)
                    }
                }
            }
            .fullScreenCover(isPresented: $isTipsPresented){
                TipsView()
            }
            .fullScreenCover(isPresented: $isAddTransactionPresented) {
                AddTransactionView( transactionToEdit: nil)
                    .environmentObject(homeViewModel.expensesViewModel)
            }
            .onAppear {
                Task {
                    await popularDadosIniciaisSeNecessario(modelContext: modelContext)
                }
                homeViewModel.loadHomeData(for: homeViewModel.currentMonth)
            }
        }
    }
    
    // MARK: - Mini Gráfico (Cartão 1) - Gráfico Interativo de Despesas Diárias
    private var miniChartCard: some View {
        VStack(alignment: .leading) {
            Text("Gastos do Mês")
                .font(.headline)
            
            if !homeViewModel.dailyExpenseChartData.isEmpty && homeViewModel.dailyExpenseChartData.contains(where: { $0.totalExpenses > 0 }) {
                InteractiveDailyExpensesChart(dailyData: homeViewModel.dailyExpenseChartData, expensesViewModel: ExpensesViewModel(modelContext: modelContext))
                    .frame(height: 150)
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "chart.bar.xaxis.ascending.badge.clock")
                        .font(.system(size: 30))
                        .foregroundColor(.secondary.opacity(0.7))
                    Text("Ainda sem gastos este mês!")
                        .font(.callout)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    Text("Seus gastos diários aparecerão aqui.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding()
            }
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 150)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    // MARK: - Planejamento (Cartão 2) - Estilo Ajustado para corresponder ao Despesas Card (com espaço vertical)
    private var planningCard: some View {
        NavigationLink {
            PlanningView()
                .environmentObject(homeViewModel.planningViewModel)
                .environmentObject(homeViewModel.expensesViewModel)
        } label: {
            VStack(alignment: .leading) {
                if homeViewModel.totalPlanejadoMes > 0 {
                    Text("Planejamento do Mês")
                        .font(.headline)
                    
                    Spacer()
                    Text("Restante do Orçamento")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    HStack {
                        Text(homeViewModel.totalRestantePlanejadoMes, format: .currency(code: "BRL"))
                            .font(.title2.bold())
                            .foregroundStyle(homeViewModel.totalRestantePlanejadoMes < 0 ? .red : .primary)
                        Text("/ \(homeViewModel.totalPlanejadoMes, format: .currency(code: "BRL"))")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 8)
                    let gastoReal = homeViewModel.totalPlanejadoMes - homeViewModel.totalRestantePlanejadoMes
                    let totalPlanejado = max(homeViewModel.totalPlanejadoMes, 1)
                    let progressoVisual = min(gastoReal, totalPlanejado)
                    
                    ProgressView(value: progressoVisual, total: totalPlanejado)
                        .tint(gastoReal > totalPlanejado ? .red : .blue)
                } else {
                    Text("Planejamento do Mês")
                        .font(.headline)
                        .padding(.bottom, 16)

                        HStack {
                            Spacer()
                            VStack(spacing: 8) {
                                Image(systemName: "pencil.and.list.clipboard")
                                    .font(.system(size: 30))
                                    .foregroundColor(.secondary.opacity(0.7))
                                Text("Vamos planejar os gastos?")
                                    .font(.callout)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                                Text("Defina suas metas para este mês.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            Spacer()
                        }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, minHeight: 150)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Despesas e Resumo Combinados (Novo Layout)
    private var expensesSummaryCombinedCard: some View {
        NavigationLink {
            ExpensesView()
                .environmentObject(homeViewModel.expensesViewModel)
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .center, spacing: 12) {
                    // COLUNA ESQUERDA
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Despesas do Mês")
                            .font(.headline)
                            .padding(.bottom, 2)

                        if homeViewModel.totalSpentMonth > 0 {
                            Text("Total Gasto:")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(homeViewModel.totalSpentMonth, format: .currency(code: "BRL"))
                                .font(.title.bold())
                                .minimumScaleFactor(0.5)
                                .lineLimit(1)
                                .frame(maxWidth: 200, alignment: .leading)
                                .padding(.bottom, 6)

                            if !homeViewModel.categoriasResumo.isEmpty {
                                Text("Categorias Principais")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)
                                    .padding(.bottom, 2)
                                ForEach(homeViewModel.categoriasResumo.prefix(3)) { item in
                                    HStack(spacing: 6) {
                                        Rectangle()
                                            .fill(item.categoria.color)
                                            .frame(width: 10, height: 10)
                                            .cornerRadius(2)
                                        Text(item.categoria.nome)
                                            .font(.subheadline)
                                            .lineLimit(1)
                                        Spacer()
                                        Text(String(format: "%.0f%%", item.percentual * 100))
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                if homeViewModel.categoriasResumo.count > 3 {
                                    HStack(spacing: 6) {
                                        Rectangle()
                                            .fill(Color.gray.opacity(0.6))
                                            .frame(width: 10, height: 10)
                                            .cornerRadius(2)
                                        Text("Outras")
                                            .font(.caption)
                                            .lineLimit(1)
                                        Spacer()
                                        let outrasPercent = homeViewModel.categoriasResumo.dropFirst(3).map { $0.percentual }.reduce(0, +)
                                        Text(String(format: "%.0f%%", outrasPercent * 100))
                                            .font(.caption.weight(.medium))
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                            
                        } else {
                            Spacer()
                            HStack {
                                Spacer()
                                VStack(spacing: 8) {
                                    Image(systemName: "creditcard")
                                        .font(.system(size: 30))
                                        .padding(.leading, 20)
                                        .foregroundColor(.secondary.opacity(0.7))
                                    Text("Sem despesas este mês")
                                        .font(.callout)
                                        .fontWeight(.medium)
                                        .padding(.leading, 20)
                                        .foregroundColor(.secondary)
                                    Text("Ótimo para o bolso ou adicione um gasto!")
                                        .font(.caption)
                                        .padding(.leading, 20)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                }
                                Spacer()
                            }
                            Spacer()
                        }

                        if homeViewModel.totalSpentMonth > 0 && homeViewModel.categoriasResumo.isEmpty {
                            Text("Resumo por categoria indisponível.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.top, 4)
                        }
                    }
                    .layoutPriority(1)
                    .frame(maxHeight: .infinity)

                    Spacer()

                    if homeViewModel.totalSpentMonth > 0 && !homeViewModel.categoriasResumo.isEmpty {
                        let categoriesWithValues = homeViewModel.categoriasResumo.filter { $0.total > 0 }
                        if !categoriesWithValues.isEmpty {
                            Chart(categoriesWithValues) { item in
                                SectorMark(
                                    angle: .value("Total Gasto", item.total),
                                    innerRadius: .ratio(0.65),
                                    angularInset: 1.5
                                )
                                .foregroundStyle(item.categoria.color)
                                .cornerRadius(5)
                                .accessibilityLabel(item.categoria.nome)
                                .accessibilityValue("\(String(format: "%.0f", item.percentual * 100))%")
                            }
                            .frame(width: 100, height: 100)
                        }
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, minHeight: 150)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityIdentifier("expensesSummaryCard")
    }
}
