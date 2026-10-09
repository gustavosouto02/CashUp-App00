import Foundation

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published private(set) var isBiometricLockEnabled: Bool
    @Published private(set) var processando = false
    @Published var errorMessage: String?

    private let service: BiometricAuthServiceProtocol
    private let settings: AppSettingsProtocol

    init(service: BiometricAuthServiceProtocol, settings: AppSettingsProtocol) {
        self.service = service
        self.settings = settings
        self.isBiometricLockEnabled = settings.isBiometricLockEnabled
    }

    var biometriaDisponivel: Bool { service.isAvailable }

    var biometria: BiometricKind { service.kind }

    func alterarBloqueio(_ ativar: Bool) async {
        guard ativar != isBiometricLockEnabled, !processando else { return }
        guard ativar else {
            definirBloqueio(false)
            return
        }
        guard service.isAvailable else {
            errorMessage = "Configure Face ID, Touch ID ou um código no iPhone para ativar o bloqueio."
            return
        }
        processando = true
        defer { processando = false }
        do {
            if try await service.authenticate(reason: "Confirme sua identidade para ativar o bloqueio do CashUp.") {
                definirBloqueio(true)
            }
        } catch {
            CashUpLogger.ui.info("Ativação do bloqueio não confirmada: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func definirBloqueio(_ valor: Bool) {
        settings.isBiometricLockEnabled = valor
        isBiometricLockEnabled = valor
    }
}
