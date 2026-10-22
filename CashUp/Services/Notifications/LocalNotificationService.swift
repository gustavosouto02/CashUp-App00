import Foundation
import UserNotifications

@MainActor
final class LocalNotificationService: NSObject, NotificationServiceProtocol, UNUserNotificationCenterDelegate {
    static let shared = LocalNotificationService()

    private enum Identificadores {
        static let lembreteDiario = "com.cashup.lembrete.diario"
        static let alertaInsight = "com.cashup.alerta.insight"
    }

    private let center: UNUserNotificationCenter

    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
        super.init()
        self.center.delegate = self
    }

    func requestAuthorization() async -> Bool {
        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    func isAuthorized() async -> Bool {
        let settings = await center.notificationSettings()
        return settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional
    }

    func agendarLembreteDiario(hora: Int, minuto: Int) {
        cancelarLembreteDiario()

        let content = UNMutableNotificationContent()
        content.title = "Hora do CashUp 💸"
        content.body = "Não deixe os gastos acumularem! Registre rapidinho o que você comprou hoje."
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = hora
        dateComponents.minute = minuto

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: Identificadores.lembreteDiario, content: content, trigger: trigger)

        center.add(request) { error in
            if let error {
                CashUpLogger.notifications.error("Falha ao agendar lembrete diário: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    func cancelarLembreteDiario() {
        center.removePendingNotificationRequests(withIdentifiers: [Identificadores.lembreteDiario])
    }

    func dispararAlertaInsight(titulo: String, mensagem: String) {
        let content = UNMutableNotificationContent()
        content.title = titulo
        content.body = mensagem
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1.0, repeats: false)
        let request = UNNotificationRequest(identifier: Identificadores.alertaInsight, content: content, trigger: trigger)

        center.add(request) { error in
            if let error {
                CashUpLogger.notifications.error("Falha ao disparar alerta de insight: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }
}
