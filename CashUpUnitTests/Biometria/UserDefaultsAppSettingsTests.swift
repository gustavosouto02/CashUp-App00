import XCTest
@testable import CashUp

final class UserDefaultsAppSettingsTests: XCTestCase {
    private let suiteName = "br.com.gustavosouto.cashup.tests.settings"

    override func tearDown() {
        UserDefaults(suiteName: suiteName)?.removePersistentDomain(forName: suiteName)
    }

    func testBloqueioComecaDesativadoEPersiste() throws {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        let sut = UserDefaultsAppSettings(defaults: defaults)

        XCTAssertFalse(sut.isBiometricLockEnabled)

        sut.isBiometricLockEnabled = true

        XCTAssertTrue(UserDefaultsAppSettings(defaults: defaults).isBiometricLockEnabled)
    }

    func testVolatilDescartaValorAnterior() {
        UserDefaultsAppSettings.volatil(suiteName: suiteName).isBiometricLockEnabled = true

        XCTAssertFalse(UserDefaultsAppSettings.volatil(suiteName: suiteName).isBiometricLockEnabled)
    }
}
