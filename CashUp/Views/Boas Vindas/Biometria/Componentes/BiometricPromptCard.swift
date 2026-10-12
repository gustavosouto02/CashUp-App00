import SwiftUI

struct BiometricPromptCard: View {
    let biometria: BiometricKind
    let autenticando: Bool
    let mensagemErro: String?
    let onDesbloquear: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: biometria.icone)
                .font(.system(size: 56))
                .foregroundStyle(.tint)

            VStack(spacing: 8) {
                Text("CashUp bloqueado")
                    .font(.system(.title2, design: .rounded).weight(.bold))
                Text("Use \(biometria.nome) para ver suas finanças.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            if let mensagemErro {
                Text(mensagemErro)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .accessibilityIdentifier("biometricErrorMessage")
            }

            Button(action: onDesbloquear) {
                Group {
                    if autenticando {
                        ProgressView()
                    } else {
                        Text("Desbloquear")
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(autenticando)
            .accessibilityIdentifier("biometricUnlockButton")
        }
        .padding(24)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 20))
    }
}

#Preview {
    BiometricPromptCard(biometria: .faceID, autenticando: false, mensagemErro: "Autenticação cancelada.", onDesbloquear: {})
        .padding()
        .preferredColorScheme(.dark)
}
