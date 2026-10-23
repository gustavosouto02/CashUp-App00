import SwiftUI

struct HomeSmartInsightBanner: View {
    let insight: FinancialInsight
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: insight.severity.iconName)
                    .font(.title3)
                    .foregroundColor(insight.severity.color)
                    .frame(width: 36, height: 36)
                    .background(insight.severity.color.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(LocalizedStringKey(insight.title))
                            .font(.subheadline.bold())
                            .foregroundColor(.white)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption2.bold())
                            .foregroundColor(.secondary)
                    }

                    Text(LocalizedStringKey(insight.message))
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
            }
            .padding(14)
            .background(Color(red: 0.11, green: 0.11, blue: 0.12))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(insight.severity.color.opacity(0.35), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
