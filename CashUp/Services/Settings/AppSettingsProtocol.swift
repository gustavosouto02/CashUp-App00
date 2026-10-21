import Foundation

protocol AppSettingsProtocol: AnyObject {
    var isBiometricLockEnabled: Bool { get set }
    var hasCompletedOnboarding: Bool { get set }
    var isDailyReminderEnabled: Bool { get set }
    var dailyReminderHour: Int { get set }
    var dailyReminderMinute: Int { get set }
    var hasPromptedNotificationPermission: Bool { get set }
}
