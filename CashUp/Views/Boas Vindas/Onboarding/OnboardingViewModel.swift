import Foundation

@MainActor
final class OnboardingViewModel: ObservableObject {
    @Published var paginaAtual: Int = 0
    let paginas: [OnboardingPage]
    private let settings: AppSettingsProtocol

    init(settings: AppSettingsProtocol, paginas: [OnboardingPage] = OnboardingPage.padrao) {
        self.settings = settings
        self.paginas = paginas
    }

    var isUltimaPagina: Bool {
        guard !paginas.isEmpty else { return true }
        return paginaAtual == paginas.count - 1
    }

    func avancar() {
        guard !paginas.isEmpty else { return }
        paginaAtual = min(paginaAtual + 1, paginas.count - 1)
    }

    func pular() {
        concluir()
    }

    func concluir() {
        settings.hasCompletedOnboarding = true
    }
}
