import SwiftUI

struct RecurringEditScopeBanner: View {
    let scope: RecurringScope

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: iconName)
                .font(.title3)
                .foregroundStyle(.blue)

            VStack(alignment: .leading, spacing: 2) {
                Text(titleText)
                    .font(.subheadline.bold())
                    .foregroundStyle(.primary)

                Text(descriptionText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(12)
        .background(Color.blue.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
        )
        .accessibilityIdentifier("recurringEditScopeBanner")
    }

    private var iconName: String {
        switch scope {
        case .thisOccurrenceOnly:
            return "calendar.badge.clock"
        case .thisAndAllFutureOccurrences:
            return "forward.fill"
        case .entireSeries:
            return "repeat"
        }
    }

    private var titleText: String {
        switch scope {
        case .thisOccurrenceOnly:
            return "Editando apenas esta ocorrência"
        case .thisAndAllFutureOccurrences:
            return "Editando esta e futuras ocorrências"
        case .entireSeries:
            return "Editando toda a série recorrente"
        }
    }

    private var descriptionText: String {
        switch scope {
        case .thisOccurrenceOnly:
            return "As outras repetições desta transação permanecerão inalteradas."
        case .thisAndAllFutureOccurrences:
            return "A série anterior será encerrada e uma nova começará nesta data."
        case .entireSeries:
            return "Todas as ocorrências passadas e futuras serão atualizadas."
        }
    }
}
