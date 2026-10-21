import XCTest
@testable import CashUp

@MainActor
final class SettingsViewModelNotificationTests: XCTestCase {
    private var authService: MockBiometricAuthService!
    private var notifService: MockNotificationService!
    private var settings: UserDefaultsAppSettings!
    private var viewModel: SettingsViewModel!

    override func setUp() {
        super.setUp()
        authService = MockBiometricAuthService()
        notifService = MockNotificationService()
        settings = UserDefaultsAppSettings.volatil(suiteName: "test.notifications.\(UUID().uuidString)")

        viewModel = SettingsViewModel(
            service: authService,
            settings: settings,
            notificationService: notifService
        )
    }

    override func tearDown() {
        viewModel = nil
        settings = nil
        notifService = nil
        authService = nil
        super.tearDown()
    }

    func testAtivarLembreteDiario_quandoAutorizadoAgendaLembreteEPersiste() async {
        notifService.requestAuthorizationResult = true

        await viewModel.alterarLembreteDiario(true)

        XCTAssertTrue(viewModel.isDailyReminderEnabled)
        XCTAssertTrue(settings.isDailyReminderEnabled)
        XCTAssertEqual(notifService.agendarLembreteCallCount, 1)
    }

    func testAtivarLembreteDiario_quandoRecusadoMostraErroENaoAtiva() async {
        notifService.requestAuthorizationResult = false

        await viewModel.alterarLembreteDiario(true)

        XCTAssertFalse(viewModel.isDailyReminderEnabled)
        XCTAssertFalse(settings.isDailyReminderEnabled)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertEqual(notifService.agendarLembreteCallCount, 0)
    }

    func testDesativarLembreteDiario_cancelaLembreteEPersiste() async {
        notifService.requestAuthorizationResult = true
        await viewModel.alterarLembreteDiario(true)

        await viewModel.alterarLembreteDiario(false)

        XCTAssertFalse(viewModel.isDailyReminderEnabled)
        XCTAssertFalse(settings.isDailyReminderEnabled)
        XCTAssertEqual(notifService.cancelarLembreteCallCount, 1)
    }

    func testAtualizarHorarioLembrete_reagendaQuandoAtivo() async {
        notifService.requestAuthorizationResult = true
        await viewModel.alterarLembreteDiario(true)

        var components = DateComponents()
        components.hour = 21
        components.minute = 30
        let novoHorario = Calendar.current.date(from: components)!

        viewModel.atualizarHorarioLembrete(novoHorario)

        XCTAssertEqual(settings.dailyReminderHour, 21)
        XCTAssertEqual(settings.dailyReminderMinute, 30)
        XCTAssertEqual(notifService.ultimaHoraAgendada, 21)
        XCTAssertEqual(notifService.ultimoMinutoAgendado, 30)
    }
}
