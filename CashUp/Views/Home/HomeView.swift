//
//  HomeView.swift
//  CashUp
//
//  Created by Gustavo Souto Pereira on 19/05/25.
//

import SwiftData
import SwiftUI

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext

    @StateObject private var homeViewModel: HomeViewModel

    @State private var isAddTransactionPresented = false
    @State private var isTipsPresented = false

    init(modelContext: ModelContext) {
        let planningVM = PlanningViewModel(modelContext: modelContext)
        let expensesVM = ExpensesViewModel(modelContext: modelContext)
        _homeViewModel = StateObject(wrappedValue: HomeViewModel(
            modelContext: modelContext,
            planningViewModel: planningVM,
            expensesViewModel: expensesVM
        ))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    MonthSelector(
                        viewModel: MonthSelectorViewModel(selectedMonth: homeViewModel.currentMonth),
                        onMonthChanged: { selectedDate in
                            homeViewModel.currentMonth = selectedDate.startOfMonth()
                        }
                    )

                    MiniChartCard(
                        dailyData: homeViewModel.dailyExpenseChartData,
                        expensesViewModel: homeViewModel.expensesViewModel
                    )

                    NavigationLink {
                        PlanningView()
                            .environmentObject(homeViewModel.planningViewModel)
                            .environmentObject(homeViewModel.expensesViewModel)
                    } label: {
                        PlanningCard(
                            totalPlanejado: homeViewModel.totalPlanejadoMes,
                            totalRestante: homeViewModel.totalRestantePlanejadoMes
                        )
                    }
                    .buttonStyle(.plain)

                    NavigationLink {
                        ExpensesView()
                            .environmentObject(homeViewModel.expensesViewModel)
                    } label: {
                        ExpensesSummaryCard(
                            totalGasto: homeViewModel.totalSpentMonth,
                            categoriasResumo: homeViewModel.categoriasResumo
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("expensesSummaryCard")

                    Spacer(minLength: 24)
                }
                .padding(.horizontal)
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
                        .accessibilityIdentifier("addTransactionButtonHome")
                    }
                }
            }
            .fullScreenCover(isPresented: $isTipsPresented) {
                TipsView()
            }
            .fullScreenCover(isPresented: $isAddTransactionPresented) {
                AddTransactionView()
                    .environmentObject(homeViewModel.expensesViewModel)
            }
            .task {
                await popularDadosIniciaisSeNecessario(modelContext: modelContext)
                homeViewModel.loadHomeData(for: homeViewModel.currentMonth)
            }
        }
    }
}
