//
//  PlanningRestanteView.swift
//  CashUp
//
//  Created by Gustavo Souto Pereira on 19/05/25.
//


import SwiftUI
import SwiftData

struct PlanningRestanteView: View {
    @ObservedObject var planningViewModel: PlanningViewModel
    @ObservedObject var expensesViewModel: ExpensesViewModel

    private var categoriasPlanejadasDoMes: [CategoriaPlanejadaModel] {
        planningViewModel.getCategoriasPlanejadasForCurrentMonth()
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                // MARK: - Meta Residual
                metaResidualCard()

                // MARK: - Categorias de Planejamento Detalhadas
                if categoriasPlanejadasDoMes.isEmpty {
                    Text("Nenhum planejamento definido para este mês.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .center)
                } else {
                    ForEach(categoriasPlanejadasDoMes) { categoriaPlanejadaModel in
                        categoriaRestanteView(categoriaPModel: categoriaPlanejadaModel)
                    }
                }
                Spacer(minLength: 24)
            }
            .padding(.horizontal)
        }
    }

    @ViewBuilder
    private func metaResidualCard() -> some View {
        let totalPlanejado = planningViewModel.valorTotalPlanejadoParaMesAtual()

        let totalGastoEmPlanejado = expensesViewModel.calcularTotalGastoEmCategoriasPlanejadas(
            paraMes: planningViewModel.currentMonth,
            categoriasPlanejadas: categoriasPlanejadasDoMes
        )
        
        let restante = totalPlanejado - totalGastoEmPlanejado
        let progresso = totalPlanejado > 0 ? min(abs(totalGastoEmPlanejado / totalPlanejado), 1.0) : 0.0
        
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 10)

                    Circle()
                        .trim(from: 0.0, to: CGFloat(progresso))
                        .stroke(
                            LinearGradient(
                                colors: restante < 0 ? [.orange, .red] : [.green, .blue],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            style: StrokeStyle(lineWidth: 10, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                    Text("\(Int(progresso * 100))%")
                        .font(.caption.bold())
                }
                .frame(width: 80, height: 80)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Restante do Planejamento")
                        .font(.subheadline)
                        .padding(.bottom, 2)

                    Text(formatCurrency(restante))
                        .font(.title.bold())
                        .foregroundStyle(restante < 0 ? .red : .primary)

                    Text("Total Planejado: \(formatCurrency(totalPlanejado))") //
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)
                }
                Spacer()
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    func categoriaRestanteView(categoriaPModel: CategoriaPlanejadaModel) -> some View {
        let totalPlanejadoCategoria = planningViewModel.totalParaCategoriaPlanejada(categoriaPModel)

        let totalGastoCategoria = categoriaPModel.subcategoriasPlanejadas?.reduce(0.0) { sum, subPlanModel in
            sum + expensesViewModel.calcularTotalGastoParaSubcategoria(
                subPlanModel,
                paraMes: planningViewModel.currentMonth
            )
        } ?? 0.0
        
        let restanteCategoria = totalPlanejadoCategoria - totalGastoCategoria

        VStack(alignment: .leading, spacing: 12) {
            HStack {
                CategoriasViewIcon(
                    systemName: categoriaPModel.iconCategoriaOriginal,
                    cor: categoriaPModel.corCategoriaOriginal,
                    size: 22
                )
                Text(categoriaPModel.nomeCategoriaOriginal)
                    .font(.headline)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                Spacer()
                Text("\(formatCurrency(restanteCategoria)) restante")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(restanteCategoria < 0 ? .red : .secondary)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
            }

            if let subcategoriasPlanejadas = categoriaPModel.subcategoriasPlanejadas, !subcategoriasPlanejadas.isEmpty {
                ForEach(subcategoriasPlanejadas.sorted(by: { $0.subcategoriaOriginal?.nome ?? "" < $1.subcategoriaOriginal?.nome ?? "" })) { subPlanModel in
                    let gastoNaSub = expensesViewModel.calcularTotalGastoParaSubcategoria(
                        subPlanModel,
                        paraMes: planningViewModel.currentMonth
                    )
                    let limiteDaSub = subPlanModel.valorPlanejado
                    let progressoSub = limiteDaSub > 0 ? min(abs(gastoNaSub / limiteDaSub), 1.0) : 0.0

                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            CategoriasViewIcon(
                                systemName: subPlanModel.iconSubcategoriaOriginal,
                                cor: categoriaPModel.corCategoriaOriginal,
                                size: 20
                            )
                            Text(subPlanModel.nomeSubcategoriaOriginal)
                                .font(.headline)
                            
                            Spacer()
                            Text("\(formatCurrency(gastoNaSub)) / \(formatCurrency(limiteDaSub))")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.leading, 8)
                        .padding(.bottom, 4)

                        ProgressView(value: progressoSub)
                            .tint(gastoNaSub > limiteDaSub ? .red : categoriaPModel.corCategoriaOriginal)
                            .padding(.leading, 8)
                    }
                    .padding(.bottom, 4)
                }
            } else {
                Text("Nenhuma subcategoria planejada.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.leading)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .frame(maxWidth: .infinity, alignment: .top)
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "pt_BR") //
        return formatter.string(from: NSNumber(value: value)) ?? "R$0,00"
    }
}
