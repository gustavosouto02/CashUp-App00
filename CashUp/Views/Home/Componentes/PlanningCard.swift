import SwiftUI

/// Cartão "Planejamento do Mês" da Home: restante do orçamento ou convite para planejar.
struct PlanningCard: View {
    let totalPlanejado: Double
    let totalRestante: Double

    var body: some View {
        VStack(alignment: .leading) {
            if totalPlanejado > 0 {
                Text("Planejamento do Mês")
                    .font(.headline)

                Spacer()
                Text("Restante do Orçamento")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack {
                    Text(BRLCurrencyFormatter.string(from: totalRestante))
                        .font(.title2.bold())
                        .foregroundStyle(totalRestante < 0 ? .red : .primary)
                    Text("/ \(BRLCurrencyFormatter.string(from: totalPlanejado))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 8)

                let gastoReal = totalPlanejado - totalRestante
                let base = max(totalPlanejado, 1)
                ProgressView(value: min(gastoReal, base), total: base)
                    .tint(gastoReal > base ? .red : .blue)
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
}
