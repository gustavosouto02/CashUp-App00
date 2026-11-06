import Foundation
import LocalAuthentication

@MainActor
final class AuthViewModel: ObservableObject {
    enum Estado: Equatable {
        case bloqueado
        case autenticando
        case liberado
        /// O usuário (ou o sistema) cancelou a autenticação: não é um erro a exibir.
        case cancelado
        /// Falha a exibir; a mensagem já vem localizada. A lógica nunca compara esse texto.
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
            let sucesso = try await service.authenticate(reason: String(localized: "Desbloqueie o CashUp para ver suas finanças."))
            estado = sucesso ? .liberado : .cancelado
        } catch {
            estado = Self.estado(para: error)
        }
    }

    func bloquear() {
        guard precisaBloquear else { return }
        estado = .bloqueado
    }

    private static func estado(para error: Error) -> Estado {
        guard let laError = error as? LAError else { return .falhou(error.localizedDescription) }
        switch laError.code {
        case .userCancel, .systemCancel, .appCancel:
            return .cancelado
        case .authenticationFailed:
            return .falhou(String(localized: "Não foi possível confirmar sua identidade."))
        default:
            return .falhou(laError.localizedDescription)
        }
    }
}
