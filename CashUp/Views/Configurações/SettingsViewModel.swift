import Foundation

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published private(set) var isBiometricLockEnabled: Bool
    @Published private(set) var isDailyReminderEnabled: Bool
    @Published var dailyReminderTime: Date
    @Published private(set) var processando = false
    @Published var errorMessage: String?

    private let service: BiometricAuthServiceProtocol
    private let settings: AppSettingsProtocol
    private let notificationService: NotificationServiceProtocol

    init(
        service: BiometricAuthServiceProtocol,
        settings: AppSettingsProtocol,
        notificationService: NotificationServiceProtocol = LocalNotificationService.shared
    ) {
        self.service = service
        self.settings = settings
        self.notificationService = notificationService
        self.isBiometricLockEnabled = settings.isBiometricLockEnabled
        self.isDailyReminderEnabled = settings.isDailyReminderEnabled

        var components = DateComponents()
        components.hour = settings.dailyReminderHour
        components.minute = settings.dailyReminderMinute
        self.dailyReminderTime = Calendar.current.date(from: components) ?? Date()
    }

    var biometriaDisponivel: Bool { service.isAvailable }

    var biometria: BiometricKind { service.kind }

    func alterarBloqueio(_ ativar: Bool) async {
        guard ativar != isBiometricLockEnabled, !processando else { return }
        guard ativar else {
            definirBloqueio(false)
            return
        }
        guard service.isAvailable else {
            errorMessage = "Configure Face ID, Touch ID ou um código no iPhone para ativar o bloqueio."
            return
        }
        processando = true
        defer { processando = false }
        do {
            if try await service.authenticate(reason: "Confirme sua identidade para ativar o bloqueio do CashUp.") {
                definirBloqueio(true)
            }
        } catch {
            CashUpLogger.ui.info("Ativação do bloqueio não confirmada: \(error.localizedDescription, privacy: .public)")
        }
    }

    func alterarLembreteDiario(_ ativar: Bool) async {
        guard ativar != isDailyReminderEnabled, !processando else { return }

        if ativar {
            let autorizado = await notificationService.requestAuthorization()
            guard autorizado else {
                errorMessage = "Para receber lembretes de gastos, permita o envio de notificações nas configurações do iPhone."
                return
            }

            let calendar = Calendar.current
            let hora = calendar.component(.hour, from: dailyReminderTime)
            let minuto = calendar.component(.minute, from: dailyReminderTime)

            settings.isDailyReminderEnabled = true
            settings.dailyReminderHour = hora
            settings.dailyReminderMinute = minuto
            isDailyReminderEnabled = true

            notificationService.agendarLembreteDiario(hora: hora, minuto: minuto)
        } else {
            settings.isDailyReminderEnabled = false
            isDailyReminderEnabled = false
            notificationService.cancelarLembreteDiario()
        }
    }

    func atualizarHorarioLembrete(_ novoHorario: Date) {
        dailyReminderTime = novoHorario
        let calendar = Calendar.current
        let hora = calendar.component(.hour, from: novoHorario)
        let minuto = calendar.component(.minute, from: novoHorario)

        settings.dailyReminderHour = hora
        settings.dailyReminderMinute = minuto

        if isDailyReminderEnabled {
            notificationService.agendarLembreteDiario(hora: hora, minuto: minuto)
        }
    }

    private func definirBloqueio(_ valor: Bool) {
        settings.isBiometricLockEnabled = valor
        isBiometricLockEnabled = valor
    }
}
