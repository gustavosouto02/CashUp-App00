import SwiftUI

struct BiometricLockView: View {
    @ObservedObject var viewModel: AuthViewModel
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack {
            Color(red: 16/255, green: 22/255, blue: 28/255)
                .ignoresSafeArea()

            BiometricPromptCard(
                biometria: viewModel.biometria,
                autenticando: viewModel.estado == .autenticando,
                mensagemErro: mensagemErro,
                onDesbloquear: { Task { await viewModel.autenticar() } }
            )
            .padding(.horizontal, 24)
        }
        .task(id: scenePhase) {
            guard scenePhase == .active, viewModel.estado == .bloqueado else { return }
            await viewModel.autenticar()
        }
    }

    private var mensagemErro: String? {
        if case .falhou(let mensagem) = viewModel.estado { return mensagem }
        return nil
    }
}
