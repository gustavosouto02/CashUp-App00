import SwiftUI

struct PrivacySecurityCard: View {
    @ObservedObject var settingsViewModel: SettingsViewModel

    var body: some View {
        VStack(spacing: 18) {
            VStack(spacing: 8) {
                Image(systemName: settingsViewModel.biometria.icone)
                    .font(.system(size: 48, weight: .regular))
                    .foregroundStyle(Color.blue)
                    .frame(height: 56)

                Text("CashUp bloqueado")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)

                Text("Use o \(settingsViewModel.biometria.nome) para entrar")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 4)

            Rectangle()
                .fill(Color.white.opacity(0.08))
                .frame(height: 1)

            VStack(spacing: 16) {
                itemLinha(
                    icone: "iphone",
                    titulo: "Armazenamento",
                    subtitulo: "Somente neste iPhone"
                )

                itemLinha(
                    icone: "network.slash",
                    titulo: "Servidores externos",
                    subtitulo: "Nenhum"
                )

                itemProtecao
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
    }

    private func itemLinha(icone: String, titulo: String, subtitulo: String) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 38, height: 38)

                Image(systemName: icone)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.blue)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(titulo)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)

                Text(subtitulo)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "checkmark")
                .font(.footnote.bold())
                .foregroundStyle(Color.blue)
        }
    }

    @ViewBuilder
    private var itemProtecao: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 38, height: 38)

                Image(systemName: "lock.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.blue)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Proteção")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)

                Text("Face ID e Touch ID")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if settingsViewModel.biometriaDisponivel {
                Toggle("", isOn: bloqueioBinding)
                    .labelsHidden()
                    .disabled(settingsViewModel.processando)
                    .accessibilityIdentifier("onboardingBiometricToggle")
            } else {
                Image(systemName: "checkmark")
                    .font(.footnote.bold())
                    .foregroundStyle(Color.blue)
            }
        }
    }

    private var bloqueioBinding: Binding<Bool> {
        Binding(
            get: { settingsViewModel.isBiometricLockEnabled },
            set: { novoValor in Task { await settingsViewModel.alterarBloqueio(novoValor) } }
        )
    }
}
