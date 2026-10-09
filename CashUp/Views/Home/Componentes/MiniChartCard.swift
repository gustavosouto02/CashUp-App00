import SwiftUI

/// Cartão "Gastos do Mês" da Home: gráfico diário interativo ou estado vazio.
struct MiniChartCard: View {
    let dailyData: [DailyExpenseItem]
    let expensesViewModel: ExpensesViewModel

    private var temGastos: Bool {
        dailyData.contains { $0.totalExpenses > 0 }
    }

    var body: some View {
        VStack(alignment: .leading) {
            Text("Gastos do Mês")
                .font(.headline)

            if temGastos {
                InteractiveDailyExpensesChart(dailyData: dailyData, expensesViewModel: expensesViewModel)
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
}
