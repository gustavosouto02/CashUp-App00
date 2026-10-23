import SwiftUI

struct SmartInsightCard: View {
    let insight: FinancialInsight

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center) {
                HStack(spacing: 6) {
                    Image(systemName: insight.severity.iconName)
                        .font(.caption.bold())
                    Text(insight.severity.badgeTitle.uppercased())
                        .font(.caption2.bold())
                        .tracking(0.5)
                }
                .foregroundColor(insight.severity.color)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(insight.severity.color.opacity(0.15))
                .clipShape(Capsule())

                Spacer()

                if let metric = insight.metricLabel {
                    Text(LocalizedStringKey(metric))
                        .font(.caption.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(LocalizedStringKey(insight.title))
                    .font(.headline)
                    .foregroundColor(.white)

                Text(LocalizedStringKey(insight.message))
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(red: 0.11, green: 0.11, blue: 0.12))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(insight.severity.color.opacity(0.3), lineWidth: 1)
        )
    }
}
