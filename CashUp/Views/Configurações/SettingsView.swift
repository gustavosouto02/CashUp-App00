import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel: SettingsViewModel
    @Environment(\.dismiss) private var dismiss

    init(service: BiometricAuthServiceProtocol, settings: AppSettingsProtocol) {
        _viewModel = StateObject(wrappedValue: SettingsViewModel(service: service, settings: settings))
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
}

#Preview {
    SettingsView(service: BiometricAuthService(), settings: UserDefaultsAppSettings())
        .preferredColorScheme(.dark)
}
