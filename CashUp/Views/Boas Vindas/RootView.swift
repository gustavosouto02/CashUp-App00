import SwiftData
import SwiftUI

struct RootView: View {
    let modelContainer: ModelContainer
    let settings: AppSettingsProtocol
    let biometricService: BiometricAuthServiceProtocol

    @StateObject private var authViewModel: AuthViewModel
    @StateObject private var onboardingViewModel: OnboardingViewModel
    @StateObject private var settingsViewModel: SettingsViewModel
    @State private var isShowingWelcomeScreen: Bool
    @State private var hasCompletedOnboarding: Bool
    @State private var dadosIniciaisProntos = false
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

        let args = ProcessInfo.processInfo.arguments
        let isUITesting = args.contains("--uitesting")
        let devePularOnboarding = isUITesting && !args.contains("--enable-onboarding")
        let jaCompletouOnboarding = devePularOnboarding ? true : settings.hasCompletedOnboarding

        _isShowingWelcomeScreen = State(initialValue: mostrarBoasVindas && !jaCompletouOnboarding)
        _hasCompletedOnboarding = State(initialValue: jaCompletouOnboarding)
        _authViewModel = StateObject(wrappedValue: AuthViewModel(service: biometricService, settings: settings))
        _onboardingViewModel = StateObject(wrappedValue: OnboardingViewModel(settings: settings))
        _settingsViewModel = StateObject(wrappedValue: SettingsViewModel(service: biometricService, settings: settings))
    }

    var body: some View {
        ZStack {
            if isShowingWelcomeScreen {
                WelcomeView(isShowingWelcomeScreen: $isShowingWelcomeScreen)
                    .transition(.opacity.animation(.easeInOut(duration: 0.5)))
            } else if !hasCompletedOnboarding {
                OnboardingView(
                    viewModel: onboardingViewModel,
                    settingsViewModel: settingsViewModel,
                    onConcluir: {
                        withAnimation(.easeInOut(duration: 0.4)) {
                            hasCompletedOnboarding = true
                        }
                    }
                )
                .transition(.opacity.animation(.easeInOut(duration: 0.4)))
            } else if authViewModel.estaBloqueado {
                BiometricLockView(viewModel: authViewModel)
                    .transition(.opacity.animation(.easeInOut(duration: 0.3)))
            } else if !dadosIniciaisProntos {
                Color.black.ignoresSafeArea()
            } else {
                HomeView(
                    modelContext: modelContainer.mainContext,
                    settings: settings,
                    biometricService: biometricService
                )
                .transition(.opacity.animation(.easeInOut(duration: 0.5)))
            }
        }
        .task {
            prepararDadosIniciais()
        }
        .onChange(of: scenePhase) { _, novaFase in
            if novaFase == .background {
                authViewModel.bloquear()
            }
        }
    }

    /// Seed e deduplicação rodam uma vez por abertura, no `MainActor`, antes de a Home ler os dados.
    private func prepararDadosIniciais() {
        guard !dadosIniciaisProntos else { return }
        let context = modelContainer.mainContext
        do {
            try SeedService(settings: settings).aplicar(em: context)
            try DeduplicacaoService().deduplicar(em: context)
        } catch {
            CashUpLogger.persistence.error("Erro ao preparar dados iniciais: \(error.localizedDescription, privacy: .public)")
        }
        dadosIniciaisProntos = true
    }
}
