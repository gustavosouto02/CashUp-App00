import SwiftData
import SwiftUI

@main
struct CashUpApp: App {
    let sharedModelContainer: ModelContainer
    private let isUITesting: Bool
    private let settings: AppSettingsProtocol
    private let biometricService: BiometricAuthServiceProtocol
    private let usandoFallbackEmMemoria: Bool
    @State private var mostrarAvisoPersistencia: Bool

    init() {
        let isUITesting = ProcessInfo.processInfo.arguments.contains("--uitesting")
        self.isUITesting = isUITesting
        settings = isUITesting ? UserDefaultsAppSettings.volatil() : UserDefaultsAppSettings()
        biometricService = BiometricAuthService()

        let resultado = Self.makeContainer(inMemory: isUITesting)
        sharedModelContainer = resultado.container
        usandoFallbackEmMemoria = resultado.usandoFallbackEmMemoria
        _mostrarAvisoPersistencia = State(initialValue: resultado.usandoFallbackEmMemoria)
    }

    /// Abre o container persistente; se falhar, cai para memória e sinaliza para a UI avisar o usuário.
    static func makeContainer(inMemory: Bool) -> (container: ModelContainer, usandoFallbackEmMemoria: Bool) {
        do {
            let container = try CashUpPersistence.makeContainer(inMemory: inMemory)
            return (container, false)
        } catch {
            CashUpLogger.persistence.critical("Container persistente falhou: \(error.localizedDescription, privacy: .public)")
            do {
                let fallback = try CashUpPersistence.makeContainer(inMemory: true)
                return (fallback, true)
            } catch let fallbackError {
                fatalError("Sem container em memória: \(fallbackError)")
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView(
                modelContainer: sharedModelContainer,
                settings: settings,
                biometricService: biometricService,
                mostrarBoasVindas: !isUITesting,
                usandoFallbackEmMemoria: usandoFallbackEmMemoria
            )
            .preferredColorScheme(.dark)
            .alert("Não foi possível abrir seus dados", isPresented: $mostrarAvisoPersistencia) {
                Button("Entendi") {}
            } message: {
                Text("O CashUp está rodando sem salvar. O que você registrar agora será perdido ao fechar o app. Não apague o app: seus dados continuam no aparelho. Feche e abra de novo; se persistir, fale com o suporte.")
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
