import Foundation
@testable import CashUp

final class MockBiometricAuthService: BiometricAuthServiceProtocol {
    var kind: BiometricKind = .faceID
    var isAvailable: Bool = true
    var resultado: Result<Bool, Error> = .success(true)
    private(set) var authenticateCallCount = 0

    func authenticate(reason: String) async throws -> Bool {
        authenticateCallCount += 1
        return try resultado.get()
    }
}

final class InMemoryAppSettings: AppSettingsProtocol {
    var isBiometricLockEnabled: Bool

    init(isBiometricLockEnabled: Bool = false) {
        self.isBiometricLockEnabled = isBiometricLockEnabled
    }
}
