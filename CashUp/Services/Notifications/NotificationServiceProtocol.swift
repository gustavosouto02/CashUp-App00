import Foundation

@MainActor
protocol NotificationServiceProtocol: AnyObject {
    func requestAuthorization() async -> Bool
    func isAuthorized() async -> Bool
    func agendarLembreteDiario(hora: Int, minuto: Int)
    func cancelarLembreteDiario()
    func dispararAlertaInsight(titulo: String, mensagem: String)
}
