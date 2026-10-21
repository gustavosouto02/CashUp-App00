import SwiftData
import SwiftUI

struct TipsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: TipsViewModel

    private let mesReferencia: Date

    init(viewModel: TipsViewModel, mes: Date = Date()) {
        self.mesReferencia = mes
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    init(modelContext: ModelContext, mes: Date = Date()) {
        self.mesReferencia = mes
        let expenseRepo = SwiftDataExpenseRepository(context: modelContext)
        let planningRepo = SwiftDataPlanningRepository(context: modelContext)
        _viewModel = StateObject(wrappedValue: TipsViewModel(
            expenseRepository: expenseRepo,
            planningRepository: planningRepo
        ))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    if !viewModel.insights.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Diagnóstico em Tempo Real")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Spacer()
                                Text("\(viewModel.insights.count) alerta(s)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            ForEach(viewModel.insights) { insight in
                                SmartInsightCard(insight: insight)
                            }
                        }
                    }

                    FiftyThirtyTwentyCard(breakdown: viewModel.ruleBreakdown)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Estratégias para seu Bolso")
                            .font(.headline)
                            .foregroundColor(.white)

                        TipCategoryChips(selectedCategory: $viewModel.selectedCategory)
                            .padding(.horizontal, -16)

                        ForEach(viewModel.dicasFiltradas) { tip in
                            TipCardView(tip: tip)
                        }
                    }

                    Spacer(minLength: 24)
                }
                .padding(.horizontal)
                .padding(.top)
            }
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("Dicas & Insights")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fechar") {
                        dismiss()
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                }
            }
            .task {
                viewModel.carregar(para: mesReferencia)
            }
        }
    }
}
