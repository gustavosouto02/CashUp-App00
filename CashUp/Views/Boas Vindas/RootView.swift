import SwiftData
import SwiftUI

struct RootView: View {
    let modelContainer: ModelContainer
    let settings: AppSettingsProtocol
    let biometricService: BiometricAuthServiceProtocol

    @StateObject private var authViewModel: AuthViewModel
    @State private var isShowingWelcomeScreen: Bool
    @Environment(\.scenePhase) private var scenePhase

    init(
        modelContainer: ModelContainer,
        settings: AppSettingsProtocol,
        biometricService: BiometricAuthServiceProtocol,
        mostrarBoasVindas: Bool
    ) {
        self.modelContainer = modelContainer
        self.settings = settings
        self.biometricService = biometricService
        _isShowingWelcomeScreen = State(initialValue: mostrarBoasVindas)
        _authViewModel = StateObject(wrappedValue: AuthViewModel(service: biometricService, settings: settings))
    }

    var body: some View {
        ZStack {
            if isShowingWelcomeScreen {
                WelcomeView(isShowingWelcomeScreen: $isShowingWelcomeScreen)
                    .transition(.opacity.animation(.easeInOut(duration: 0.5)))
            } else if authViewModel.estaBloqueado {
                BiometricLockView(viewModel: authViewModel)
                    .transition(.opacity.animation(.easeInOut(duration: 0.3)))
            } else {
                HomeView(
                    modelContext: modelContainer.mainContext,
                    settings: settings,
                    biometricService: biometricService
                )
                .transition(.opacity.animation(.easeInOut(duration: 0.5)))
            }
        }
        .onChange(of: scenePhase) { _, novaFase in
            if novaFase == .background {
                authViewModel.bloquear()
            }
        }
    }
}
