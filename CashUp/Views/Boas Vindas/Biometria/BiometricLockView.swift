import SwiftUI

struct BiometricLockView: View {
    @ObservedObject var viewModel: AuthViewModel
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack {
            Color(red: 16/255, green: 22/255, blue: 28/255)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Image("IconCashUp")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 130, height: 130)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.25), radius: 10, x: 0, y: 5)

                Text("CashUp")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }

            VStack {
                Spacer()

                VStack(spacing: 12) {
                    if let mensagemErro {
                        Text(mensagemErro)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                            .accessibilityIdentifier("biometricErrorMessage")
                    }

                    Button {
                        Task { await viewModel.autenticar() }
                    } label: {
                        HStack(spacing: 8) {
                            if viewModel.estado == .autenticando {
                                ProgressView()
                                    .tint(.white)
                            }
                            Text("Usar senha do celular")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white)
                        }
                        .padding(.horizontal, 28)
                        .padding(.vertical, 14)
                        .background(Color.white.opacity(0.12))
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                    }
                    .disabled(viewModel.estado == .autenticando)
                    .accessibilityIdentifier("biometricUnlockButton")
                }
                .padding(.bottom, 36)
            }
        }
        .task(id: scenePhase) {
            guard scenePhase == .active, viewModel.estado == .bloqueado else { return }
            await viewModel.autenticar()
        }
    }

    private var mensagemErro: String? {
        if case .falhou(let mensagem) = viewModel.estado, mensagem != "Autenticação cancelada." {
            return mensagem
        }
        return nil
    }
}
