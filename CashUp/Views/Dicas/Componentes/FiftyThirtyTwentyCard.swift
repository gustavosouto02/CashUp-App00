import SwiftUI

struct FiftyThirtyTwentyCard: View {
    let breakdown: FiftyThirtyTwentyBreakdown?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "chart.pie.fill")
                    .font(.title3)
                    .foregroundColor(Color(red: 0.25, green: 0.88, blue: 0.45))

                Text("A Regra 50/30/20 na Sua Carteira")
                    .font(.headline)
                    .foregroundColor(.white)

                Spacer()
            }

            Text("O método clássico para dividir sua renda sem passar aperto: 50% para necessidades, 30% para estilo de vida e 20% para poupança.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineSpacing(2)

            if let b = breakdown, b.rendaTotal > 0 {
                Divider()
                    .background(Color.white.opacity(0.1))

                VStack(spacing: 12) {
                    linhaBarra(
                        titulo: "Necessidades (Moradia, Comida, Saúde)",
                        alvo: "Meta: 50%",
                        atual: b.pctNecessidades,
                        valorAtual: b.necessidades,
                        cor: Color(red: 0.22, green: 0.74, blue: 0.98)
                    )

                    linhaBarra(
                        titulo: "Desejos Pessoais (Lazer, Compras)",
                        alvo: "Meta: 30%",
                        atual: b.pctDesejos,
                        valorAtual: b.desejos,
                        cor: Color(red: 1.0, green: 0.76, blue: 0.18)
                    )

                    linhaBarra(
                        titulo: "Poupança & Futuro",
                        alvo: "Meta: 20%",
                        atual: b.pctPoupanca,
                        valorAtual: b.poupanca,
                        cor: Color(red: 0.25, green: 0.88, blue: 0.45)
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(red: 0.11, green: 0.11, blue: 0.12))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func linhaBarra(titulo: String, alvo: String, atual: Double, valorAtual: Double, cor: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(titulo)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.9))
                Spacer()
                Text("\(Int(atual))% (\(BRLCurrencyFormatter.string(from: valorAtual)))")
                    .font(.caption.bold())
                    .foregroundColor(.white)
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.08))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(cor)
                        .frame(width: min(proxy.size.width * CGFloat(min(atual, 100.0) / 100.0), proxy.size.width), height: 8)
                }
            }
            .frame(height: 8)

            Text(alvo)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}
