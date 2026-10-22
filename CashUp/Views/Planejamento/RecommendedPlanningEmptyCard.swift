import SwiftUI

struct RecommendedPlanningEmptyCard: View {
    let onCriarPlanejamento: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.blue.opacity(0.85), Color.purple.opacity(0.85)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                        .shadow(color: Color.blue.opacity(0.3), radius: 6, x: 0, y: 3)

                    Image(systemName: "chart.pie.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("Assistente de Orçamento")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)

                    Text("Comece com um planejamento recomendado")
                        .font(.headline)
                        .foregroundStyle(.primary)
                }
                Spacer()
            }

            Text("Informe sua renda mensal e calculamos uma divisão equilibrada (50/30/20) para as suas categorias essenciais, estilo de vida e poupança.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)

            Button(action: {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                onCriarPlanejamento()
            }) {
                Text("Gerar Planejamento Recomendado")
                    .font(.system(size: 15, weight: .bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [Color.blue, Color(red: 0.35, green: 0.38, blue: 0.95)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .shadow(color: Color.blue.opacity(0.25), radius: 8, x: 0, y: 4)
            }
            .accessibilityIdentifier("recommended_planning_empty_card_button")
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.blue.opacity(0.18), lineWidth: 1)
                )
        )
        .padding(.horizontal)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("recommended_planning_empty_card")
    }
}
