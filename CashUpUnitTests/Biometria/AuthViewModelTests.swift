import LocalAuthentication
import XCTest
@testable import CashUp

@MainActor
final class AuthViewModelTests: XCTestCase {
    private var service: MockBiometricAuthService!
    private var settings: InMemoryAppSettings!

    override func setUp() {
        service = MockBiometricAuthService()
        settings = InMemoryAppSettings(isBiometricLockEnabled: true)
    }

    override func tearDown() {
        service = nil
        settings = nil
    }

    private func makeSUT() -> AuthViewModel {
        AuthViewModel(service: service, settings: settings)
    }

    func testIniciaBloqueadoQuandoBloqueioAtivoEDisponivel() {
        let sut = makeSUT()

        XCTAssertTrue(sut.precisaBloquear)
        XCTAssertEqual(sut.estado, .bloqueado)
        XCTAssertTrue(sut.estaBloqueado)
    }

    func testAutenticacaoComSucessoLibera() async {
        let sut = makeSUT()

        await sut.autenticar()

        XCTAssertEqual(sut.estado, .liberado)
        XCTAssertFalse(sut.estaBloqueado)
        XCTAssertEqual(service.authenticateCallCount, 1)
    }

    func testAutenticacaoRecusadaFalha() async {
        service.resultado = .success(false)
        let sut = makeSUT()

        await sut.autenticar()

        XCTAssertEqual(sut.estado, .falhou("Autenticação cancelada."))
        XCTAssertTrue(sut.estaBloqueado)
    }

    func testCancelamentoDoUsuarioFalhaComMensagem() async {
        service.resultado = .failure(LAError(.userCancel))
        let sut = makeSUT()

        await sut.autenticar()

        XCTAssertEqual(sut.estado, .falhou("Autenticação cancelada."))
    }

    func testFalhaDeAutenticacaoFalhaComMensagem() async {
        service.resultado = .failure(LAError(.authenticationFailed))
        let sut = makeSUT()

        await sut.autenticar()

        XCTAssertEqual(sut.estado, .falhou("Não foi possível confirmar sua identidade."))
    }

    func testBiometriaIndisponivelNaoBloqueia() async {
        service.isAvailable = false
        let sut = makeSUT()

        XCTAssertFalse(sut.precisaBloquear)
        XCTAssertEqual(sut.estado, .liberado)

        sut.bloquear()
        await sut.autenticar()

        XCTAssertEqual(sut.estado, .liberado)
        XCTAssertEqual(service.authenticateCallCount, 0)
    }

    func testBloqueioDesativadoNasSettingsNaoBloqueia() {
        settings.isBiometricLockEnabled = false
        let sut = makeSUT()

        XCTAssertFalse(sut.precisaBloquear)
        XCTAssertEqual(sut.estado, .liberado)

        sut.bloquear()

        XCTAssertEqual(sut.estado, .liberado)
    }

    func testBloquearAposLiberarVoltaABloqueado() async {
        let sut = makeSUT()
        await sut.autenticar()

        sut.bloquear()

        XCTAssertEqual(sut.estado, .bloqueado)
    }

    func testBiometriaRemovidaEnquantoBloqueadoLiberaSemPedirAutenticacao() async {
        let sut = makeSUT()
        service.isAvailable = false

        await sut.autenticar()

        XCTAssertEqual(sut.estado, .liberado)
        XCTAssertEqual(service.authenticateCallCount, 0)
    }
}
