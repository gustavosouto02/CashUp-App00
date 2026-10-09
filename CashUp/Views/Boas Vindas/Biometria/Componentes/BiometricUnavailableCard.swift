import SwiftUI

struct BiometricUnavailableCard: View {
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "exclamationmark.lock.fill")
                .font(.title2)
                .foregroundStyle(.orange)

            VStack(alignment: .leading, spacing: 4) {
                Text("Bloqueio indisponível")
                    .font(.headline)
                Text("Configure Face ID, Touch ID ou um código nos Ajustes do iPhone para proteger o CashUp.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("biometricUnavailableCard")
    }
}

#Preview {
    BiometricUnavailableCard()
        .padding()
        .preferredColorScheme(.dark)
}
