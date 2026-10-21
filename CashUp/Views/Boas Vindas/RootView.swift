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

        _isShowingWelcomeScreen = State(initialValue: mostrarBoasVindas)
        _hasCompletedOnboarding = State(initialValue: devePularOnboarding ? true : settings.hasCompletedOnboarding)
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
        .task {
            if !ProcessInfo.processInfo.arguments.contains("--uitesting") {
                await solicitarPermissaoInicialNotificacoes()
            }
        }
    }

    private func solicitarPermissaoInicialNotificacoes() async {
        guard !settings.hasPromptedNotificationPermission else { return }
        settings.hasPromptedNotificationPermission = true
        let notificationService = LocalNotificationService.shared
        let autorizado = await notificationService.requestAuthorization()
        if autorizado {
            settings.isDailyReminderEnabled = true
            let hora = settings.dailyReminderHour
            let minuto = settings.dailyReminderMinute
            notificationService.agendarLembreteDiario(hora: hora, minuto: minuto)
        }
    }
}
