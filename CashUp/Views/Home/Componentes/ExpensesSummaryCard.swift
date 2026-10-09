import Charts
import SwiftUI

/// Cartão "Despesas do Mês" da Home: total gasto, categorias principais e gráfico de setores.
struct ExpensesSummaryCard: View {
    let totalGasto: Double
    let categoriasResumo: [CategoriaResumo]

    private var categoriasComValor: [CategoriaResumo] {
        categoriasResumo.filter { $0.total > 0 }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Despesas do Mês")
                        .font(.headline)
                        .padding(.bottom, 2)

                    if totalGasto > 0 {
                        resumo
                    } else {
                        estadoVazio
                    }

                    if totalGasto > 0 && categoriasResumo.isEmpty {
                        Text("Resumo por categoria indisponível.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.top, 4)
                    }
                }
                .layoutPriority(1)
                .frame(maxHeight: .infinity)

                Spacer()

                if totalGasto > 0 && !categoriasComValor.isEmpty {
                    Chart(categoriasComValor) { item in
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
        .padding()
        .frame(maxWidth: .infinity, minHeight: 150)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    @ViewBuilder
    private var resumo: some View {
        Text("Total Gasto:")
            .font(.caption)
            .foregroundStyle(.secondary)
        Text(totalGasto, format: .currency(code: "BRL"))
            .font(.title.bold())
            .minimumScaleFactor(0.5)
            .lineLimit(1)
            .frame(maxWidth: 200, alignment: .leading)
            .padding(.bottom, 6)

        if !categoriasResumo.isEmpty {
            Text("Categorias Principais")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.bottom, 2)
            ForEach(categoriasResumo.prefix(3)) { item in
                linha(cor: item.categoria.color, nome: item.categoria.nome, percentual: item.percentual)
            }
            if categoriasResumo.count > 3 {
                let outras = categoriasResumo.dropFirst(3).map(\.percentual).reduce(0, +)
                linha(cor: Color.gray.opacity(0.6), nome: "Outras", percentual: outras)
            }
        }
    }

    private func linha(cor: Color, nome: String, percentual: Double) -> some View {
        HStack(spacing: 6) {
            Rectangle()
                .fill(cor)
                .frame(width: 10, height: 10)
                .cornerRadius(2)
            Text(nome)
                .font(.subheadline)
                .lineLimit(1)
            Spacer()
            Text(String(format: "%.0f%%", percentual * 100))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var estadoVazio: some View {
        VStack {
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
    }
}
