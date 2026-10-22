import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel: SettingsViewModel
    @Environment(\.dismiss) private var dismiss

    init(
        service: BiometricAuthServiceProtocol,
        settings: AppSettingsProtocol,
        notificationService: NotificationServiceProtocol = LocalNotificationService.shared
    ) {
        _viewModel = StateObject(wrappedValue: SettingsViewModel(
            service: service,
            settings: settings,
            notificationService: notificationService
        ))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    if viewModel.biometriaDisponivel {
                        Toggle(isOn: bloqueioBinding) {
                            Label("Bloquear com \(viewModel.biometria.nome)", systemImage: viewModel.biometria.icone)
                        }
                        .disabled(viewModel.processando)
                        .accessibilityIdentifier("biometricLockToggle")
                    } else {
                        BiometricUnavailableCard()
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                    }
                } header: {
                    Text("Segurança")
                } footer: {
                    Text("Ao ativar, o CashUp pede autenticação sempre que você voltar ao app.")
                }

                Section {
                    Toggle(isOn: lembreteBinding) {
                        Label("Lembrete Diário de Gastos", systemImage: "bell.fill")
                    }

                    if viewModel.isDailyReminderEnabled {
                        DatePicker(
                            "Horário do lembrete",
                            selection: horarioBinding,
                            displayedComponents: .hourAndMinute
                        )
                    }
                } header: {
                    Text("Lembretes & Notificações")
                } footer: {
                    Text("Receba um lembrete diário para não deixar os gastos acumularem.")
                }
            }
            .navigationTitle("Configurações")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("OK") { dismiss() }
                }
            }
            .errorAlert($viewModel.errorMessage)
        }
    }

    private var bloqueioBinding: Binding<Bool> {
        Binding(
            get: { viewModel.isBiometricLockEnabled },
            set: { novoValor in Task { await viewModel.alterarBloqueio(novoValor) } }
        )
    }

    private var lembreteBinding: Binding<Bool> {
        Binding(
            get: { viewModel.isDailyReminderEnabled },
            set: { novoValor in Task { await viewModel.alterarLembreteDiario(novoValor) } }
        )
    }

    private var horarioBinding: Binding<Date> {
        Binding(
            get: { viewModel.dailyReminderTime },
            set: { novoHorario in viewModel.atualizarHorarioLembrete(novoHorario) }
        )
    }
}

#Preview {
    SettingsView(service: BiometricAuthService(), settings: UserDefaultsAppSettings())
        .preferredColorScheme(.dark)
}
