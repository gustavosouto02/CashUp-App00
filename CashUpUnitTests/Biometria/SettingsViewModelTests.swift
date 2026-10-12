import LocalAuthentication
import XCTest
@testable import CashUp

@MainActor
final class SettingsViewModelTests: XCTestCase {
    private var service: MockBiometricAuthService!
    private var settings: InMemoryAppSettings!
    private var sut: SettingsViewModel!

    override func setUp() {
        service = MockBiometricAuthService()
        settings = InMemoryAppSettings()
        sut = SettingsViewModel(service: service, settings: settings)
    }

    override func tearDown() {
        service = nil
        settings = nil
        sut = nil
    }

    func testAtivarBloqueioExigeAutenticacao() async {
        await sut.alterarBloqueio(true)

        XCTAssertTrue(sut.isBiometricLockEnabled)
        XCTAssertTrue(settings.isBiometricLockEnabled)
        XCTAssertEqual(service.authenticateCallCount, 1)
    }

    func testAtivarBloqueioCanceladoMantemDesativado() async {
        service.resultado = .failure(LAError(.userCancel))

        await sut.alterarBloqueio(true)

        XCTAssertFalse(sut.isBiometricLockEnabled)
        XCTAssertFalse(settings.isBiometricLockEnabled)
        XCTAssertNil(sut.errorMessage)
    }

    func testAtivarBloqueioSemBiometriaMostraErro() async {
        service.isAvailable = false

        await sut.alterarBloqueio(true)

        XCTAssertFalse(settings.isBiometricLockEnabled)
        XCTAssertNotNil(sut.errorMessage)
        XCTAssertEqual(service.authenticateCallCount, 0)
    }

    func testDesativarBloqueioNaoPedeAutenticacao() async {
        settings.isBiometricLockEnabled = true
        sut = SettingsViewModel(service: service, settings: settings)

        await sut.alterarBloqueio(false)

        XCTAssertFalse(sut.isBiometricLockEnabled)
        XCTAssertFalse(settings.isBiometricLockEnabled)
        XCTAssertEqual(service.authenticateCallCount, 0)
    }
}
