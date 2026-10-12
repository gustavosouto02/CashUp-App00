import Foundation

final class UserDefaultsAppSettings: AppSettingsProtocol {
    private enum Chave {
        static let bloqueioBiometrico = "settings.isBiometricLockEnabled"
        static let onboardingConcluido = "settings.hasCompletedOnboarding"
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    static func volatil(suiteName: String = "br.com.gustavosouto.cashup.uitesting") -> UserDefaultsAppSettings {
        let defaults = UserDefaults(suiteName: suiteName) ?? .standard
        defaults.removePersistentDomain(forName: suiteName)
        return UserDefaultsAppSettings(defaults: defaults)
    }

    var isBiometricLockEnabled: Bool {
        get { defaults.bool(forKey: Chave.bloqueioBiometrico) }
        set { defaults.set(newValue, forKey: Chave.bloqueioBiometrico) }
    }

    var hasCompletedOnboarding: Bool {
        get { defaults.bool(forKey: Chave.onboardingConcluido) }
        set { defaults.set(newValue, forKey: Chave.onboardingConcluido) }
    }
}
