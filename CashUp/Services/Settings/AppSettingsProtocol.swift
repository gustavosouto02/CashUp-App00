import Foundation

protocol AppSettingsProtocol: AnyObject {
    var isBiometricLockEnabled: Bool { get set }
    var hasCompletedOnboarding: Bool { get set }
}
