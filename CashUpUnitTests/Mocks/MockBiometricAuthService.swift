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
    var hasCompletedOnboarding: Bool
    var isDailyReminderEnabled: Bool
    var dailyReminderHour: Int
    var dailyReminderMinute: Int
    var hasPromptedNotificationPermission: Bool

    init(
        isBiometricLockEnabled: Bool = false,
        hasCompletedOnboarding: Bool = false,
        isDailyReminderEnabled: Bool = false,
        dailyReminderHour: Int = 20,
        dailyReminderMinute: Int = 0,
        hasPromptedNotificationPermission: Bool = false
    ) {
        self.isBiometricLockEnabled = isBiometricLockEnabled
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.isDailyReminderEnabled = isDailyReminderEnabled
        self.dailyReminderHour = dailyReminderHour
        self.dailyReminderMinute = dailyReminderMinute
        self.hasPromptedNotificationPermission = hasPromptedNotificationPermission
    }
}
