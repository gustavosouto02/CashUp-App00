//
//  PlanningView.swift
//  CashUp
//
//  Created by Gustavo Souto Pereira on 19/05/25.
//

import SwiftUI
import SwiftData

struct PlanningView: View {
    @Environment(\.sizeCategory) var sizeCategory

    @EnvironmentObject var planningViewModel: PlanningViewModel
    @EnvironmentObject var expensesViewModel: ExpensesViewModel

    @State private var isEditing: Bool = false
    @State private var subcategoriasPlanejadasSelecionadasParaDelecao: Set<UUID> = []

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    MonthSelector(
                        viewModel: MonthSelectorViewModel(selectedMonth: planningViewModel.currentMonth),
                        onMonthChanged: { selectedDate in
                            let newMonth = selectedDate.startOfMonth()
                            planningViewModel.currentMonth = newMonth
                            expensesViewModel.currentMonth = newMonth
                        }
                    )
                    .padding(.top, 20)
                    .padding(.horizontal)

                    Picker("Modo", selection: $planningViewModel.selectedTab) {
                        Text("Planejar").tag(0)
                        Text("Restante").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    if planningViewModel.selectedTab == 0 {
                        PlanningPlanejarView(
                            viewModel: planningViewModel,
                            isEditing: $isEditing,
                            subcategoriasSelecionadas: $subcategoriasPlanejadasSelecionadasParaDelecao
                        )
                        .id("PlanejarView-\(planningViewModel.currentMonth.timeIntervalSince1970)")
                    } else {
                        PlanningRestanteView(
                            planningViewModel: planningViewModel,
                            expensesViewModel: expensesViewModel
                        )
                        .id("RestanteView-\(planningViewModel.currentMonth.timeIntervalSince1970)")
                    }
                }
            }
            .navigationTitle("Planejamento")
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button {
                        planningViewModel.confirmCopyCurrentMonthPlanningToNextMonth()
                    } label: {
                        Label("Copiar para Próximo Mês", systemImage: "document.on.document.fill")
                    }
                }
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    if planningViewModel.selectedTab == 0 {
                        if isEditing {
                            Button(action: {
                                planningViewModel.removerSubcategoriasPlanejadasSelecionadas(idsSubcategoriasPlanejadas: subcategoriasPlanejadasSelecionadasParaDelecao)
                                subcategoriasPlanejadasSelecionadasParaDelecao.removeAll()
                                isEditing = false
                            }) {
                                Image(systemName: "trash.fill")
                            }
                            .foregroundStyle(.red)
                            .disabled(subcategoriasPlanejadasSelecionadasParaDelecao.isEmpty)
                        }

                        Button(action: {
                            isEditing.toggle()
                            if !isEditing {
                                subcategoriasPlanejadasSelecionadasParaDelecao.removeAll()
                            }
                        }) {
                            Text(isEditing ? "Concluir" : "Editar")
                        }
                    }
                }
            }
            .alert(
                planningViewModel.copyPlanningAlertTitle,
                isPresented: $planningViewModel.showCopyConfirmationAlert
            ) {
                Button("Cancelar", role: .cancel) { }
                Button("Copiar") {
                    planningViewModel.executeCopyPlanning()
                }
            } message: {
                Text(planningViewModel.copyPlanningAlertMessage)
            }
            .alert(
                planningViewModel.copyResultAlertTitle,
                isPresented: $planningViewModel.showCopyResultAlert
            ) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(planningViewModel.copyResultAlertMessage)
            }
        }
    }
}

