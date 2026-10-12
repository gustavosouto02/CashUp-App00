import Foundation
import LocalAuthentication

@MainActor
final class AuthViewModel: ObservableObject {
    enum Estado: Equatable {
        case bloqueado
        case autenticando
        case liberado
        case falhou(String)
    }

    @Published private(set) var estado: Estado

    private let service: BiometricAuthServiceProtocol
    private let settings: AppSettingsProtocol

    init(service: BiometricAuthServiceProtocol, settings: AppSettingsProtocol) {
        self.service = service
        self.settings = settings
        self.estado = settings.isBiometricLockEnabled && service.isAvailable ? .bloqueado : .liberado
    }

    var precisaBloquear: Bool { settings.isBiometricLockEnabled && service.isAvailable }

    var estaBloqueado: Bool { estado != .liberado }

    var biometria: BiometricKind { service.kind }

    func autenticar() async {
        guard estado != .autenticando else { return }
        guard precisaBloquear else {
            estado = .liberado
            return
        }
        estado = .autenticando
        do {
            let sucesso = try await service.authenticate(reason: "Desbloqueie o CashUp para ver suas finanças.")
            estado = sucesso ? .liberado : .falhou("Autenticação cancelada.")
        } catch {
            estado = .falhou(Self.mensagem(para: error))
        }
    }

    func bloquear() {
        guard precisaBloquear else { return }
        estado = .bloqueado
    }

    private static func mensagem(para error: Error) -> String {
        guard let laError = error as? LAError else { return error.localizedDescription }
        switch laError.code {
        case .userCancel, .systemCancel, .appCancel:
            return "Autenticação cancelada."
        case .authenticationFailed:
            return "Não foi possível confirmar sua identidade."
        default:
            return laError.localizedDescription
        }
    }
}
