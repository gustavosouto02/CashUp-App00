import Foundation
@testable import CashUp

@MainActor
final class MockNotificationService: NotificationServiceProtocol {
    var isAuthorizedResult: Bool = true
    var requestAuthorizationResult: Bool = true

    var agendarLembreteCallCount: Int = 0
    var cancelarLembreteCallCount: Int = 0
    var dispararAlertaCallCount: Int = 0

    var ultimaHoraAgendada: Int?
    var ultimoMinutoAgendado: Int?

    func requestAuthorization() async -> Bool {
        requestAuthorizationResult
    }

    func isAuthorized() async -> Bool {
        isAuthorizedResult
    }

    func agendarLembreteDiario(hora: Int, minuto: Int) {
        agendarLembreteCallCount += 1
        ultimaHoraAgendada = hora
        ultimoMinutoAgendado = minuto
    }

    func cancelarLembreteDiario() {
        cancelarLembreteCallCount += 1
    }

    func dispararAlertaInsight(titulo: String, mensagem: String) {
        dispararAlertaCallCount += 1
    }
}
