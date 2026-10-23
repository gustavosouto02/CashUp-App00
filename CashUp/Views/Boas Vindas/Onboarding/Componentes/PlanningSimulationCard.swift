import SwiftUI

struct PlanningSimulationCard: View {
    @State private var animarProgresso: Bool = false

    private struct ItemPlanejado: Identifiable {
        let id = UUID()
        let nome: String
        let detalhe: String
        let progresso: Double
        let corDestaque: Color?
        let corBarra: Color
    }

    private var itens: [ItemPlanejado] {
        [
            ItemPlanejado(
                nome: String(localized: "Mercado"),
                detalhe: String(localized: "\(BRLCurrencyFormatter.string(from: 680)) de \(BRLCurrencyFormatter.string(from: 1000))"),
                progresso: 0.68,
                corDestaque: nil,
                corBarra: .blue
            ),
            ItemPlanejado(
                nome: String(localized: "Restaurantes"),
                detalhe: String(localized: "Restam \(BRLCurrencyFormatter.string(from: 70))"),
                progresso: 0.93,
                corDestaque: Color(red: 255/255, green: 179/255, blue: 64/255),
                corBarra: Color(red: 255/255, green: 179/255, blue: 64/255)
            ),
            ItemPlanejado(
                nome: String(localized: "Delivery"),
                detalhe: String(localized: "\(BRLCurrencyFormatter.string(from: 220)) de \(BRLCurrencyFormatter.string(from: 350))"),
                progresso: 0.63,
                corDestaque: nil,
                corBarra: .blue
            ),
            ItemPlanejado(
                nome: String(localized: "Transporte"),
                detalhe: String(localized: "\(BRLCurrencyFormatter.string(from: 190)) de \(BRLCurrencyFormatter.string(from: 400))"),
                progresso: 0.47,
                corDestaque: nil,
                corBarra: .blue
            )
        ]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(mesAtualNome)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)

                Spacer()

                Text("Tetos do mês")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(BRLCurrencyFormatter.string(from: 1240))
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("ainda sobra para gastar")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, 2)

            Rectangle()
                .fill(Color.white.opacity(0.08))
                .frame(height: 1)
                .padding(.vertical, 2)

            VStack(spacing: 14) {
                ForEach(itens) { item in
                    VStack(spacing: 6) {
                        HStack {
                            Text(item.nome)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.white)

                            Spacer()

                            Text(item.detalhe)
                                .font(.caption.weight(item.corDestaque != nil ? .bold : .medium))
                                .foregroundStyle(item.corDestaque ?? Color(.lightGray))
                        }

                        GeometryReader { proxy in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color.white.opacity(0.1))
                                    .frame(height: 5)

                                Capsule()
                                    .fill(item.corBarra)
                                    .frame(width: proxy.size.width * (animarProgresso ? item.progresso : 0), height: 5)
                                    .animation(.spring(response: 0.8, dampingFraction: 0.75).delay(0.1), value: animarProgresso)
                            }
                        }
                        .frame(height: 5)
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(red: 22/255, green: 28/255, blue: 36/255))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
        .onAppear {
            animarProgresso = true
        }
    }

    private var mesAtualNome: String {
        Date().formatted(.dateTime.month(.wide).locale(.autoupdatingCurrent)).capitalized
    }
}
