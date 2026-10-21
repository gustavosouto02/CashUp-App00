import SwiftUI

struct TipCardView: View {
    let tip: Tip

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: tip.icon)
                .font(.title2)
                .foregroundColor(corDaCategoria)
                .frame(width: 40, height: 40)
                .background(corDaCategoria.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(tip.title)
                        .font(.headline)
                        .foregroundColor(.white)

                    Spacer()

                    Text(tip.tag)
                        .font(.caption2.bold())
                        .foregroundColor(corDaCategoria)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(corDaCategoria.opacity(0.12))
                        .clipShape(Capsule())
                }

                Text(tip.body)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(2)
            }
        }
        .padding(16)
        .background(Color(red: 0.11, green: 0.11, blue: 0.12))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var corDaCategoria: Color {
        switch tip.category {
        case .orcamento:
            return Color(red: 0.22, green: 0.74, blue: 0.98)
        case .economia:
            return Color(red: 0.25, green: 0.88, blue: 0.45)
        case .habitos:
            return Color(red: 1.0, green: 0.76, blue: 0.18)
        case .renda:
            return Color(red: 0.65, green: 0.55, blue: 0.98)
        }
    }
}
