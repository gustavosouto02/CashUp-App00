import XCTest
@testable import CashUp

@MainActor
final class OnboardingViewModelTests: XCTestCase {
    private var settings: InMemoryAppSettings!

    override func setUp() {
        settings = InMemoryAppSettings(isBiometricLockEnabled: false, hasCompletedOnboarding: false)
    }

    override func tearDown() {
        settings = nil
    }

    private func makeSUT(paginas: [OnboardingPage] = OnboardingPage.padrao) -> OnboardingViewModel {
        OnboardingViewModel(settings: settings, paginas: paginas)
    }

    func testIniciaNaPrimeiraPagina() {
        let sut = makeSUT()

        XCTAssertEqual(sut.paginaAtual, 0)
        XCTAssertFalse(sut.isUltimaPagina)
    }

    func testAvancarIncrementaPaginaAtual() {
        let sut = makeSUT()

        sut.avancar()

        XCTAssertEqual(sut.paginaAtual, 1)
        XCTAssertFalse(sut.isUltimaPagina)
    }

    func testAvancarNaoPassaDaUltimaPagina() {
        let sut = makeSUT()

        sut.avancar()
        sut.avancar()
        XCTAssertEqual(sut.paginaAtual, 2)
        XCTAssertTrue(sut.isUltimaPagina)

        sut.avancar()
        XCTAssertEqual(sut.paginaAtual, 2)
    }

    func testPularMarcaOnboardingConcluido() {
        let sut = makeSUT()

        sut.pular()

        XCTAssertTrue(settings.hasCompletedOnboarding)
    }

    func testConcluirMarcaOnboardingConcluido() {
        let sut = makeSUT()

        sut.concluir()

        XCTAssertTrue(settings.hasCompletedOnboarding)
    }

    func testListaPadraoPossuiTresPaginas() {
        let sut = makeSUT()

        XCTAssertEqual(sut.paginas.count, 3)
        XCTAssertEqual(sut.paginas[0].titulo, "Registre em segundos")
        XCTAssertEqual(sut.paginas[1].titulo, "Planeje o mês")
        XCTAssertEqual(sut.paginas[2].titulo, "Seus dados são seus")
    }
}
