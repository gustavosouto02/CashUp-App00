import SwiftData
import SwiftUI

@main
struct CashUpApp: App {
    let sharedModelContainer: ModelContainer
    @State private var isShowingWelcomeScreen: Bool = true
    @State private var mostrarAvisoPersistencia: Bool

    init() {
        let isUITesting = ProcessInfo.processInfo.arguments.contains("--uitesting")
        _isShowingWelcomeScreen = State(initialValue: !isUITesting)

        let resultado = Self.makeContainer(inMemory: isUITesting)
        sharedModelContainer = resultado.container
        _mostrarAvisoPersistencia = State(initialValue: resultado.usandoFallbackEmMemoria)
    }

    /// Abre o container persistente; se falhar, cai para memória e sinaliza para a UI avisar o usuário.
    static func makeContainer(inMemory: Bool) -> (container: ModelContainer, usandoFallbackEmMemoria: Bool) {
        let schema = Schema([
            CategoriaModel.self,
            SubcategoriaModel.self,
            ExpenseModel.self,
            CategoriaPlanejadaModel.self,
            SubcategoriaPlanejadaModel.self,
        ])
        do {
            let container = try ModelContainer(
                for: schema,
                configurations: ModelConfiguration(schema: schema, isStoredInMemoryOnly: inMemory)
            )
            return (container, false)
        } catch {
            CashUpLogger.persistence.critical("Container persistente falhou: \(error.localizedDescription, privacy: .public)")
            do {
                let fallback = try ModelContainer(
                    for: schema,
                    configurations: ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
                )
                return (fallback, true)
            } catch let fallbackError {
                fatalError("Sem container em memória: \(fallbackError)")
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                if isShowingWelcomeScreen {
                    WelcomeView(isShowingWelcomeScreen: $isShowingWelcomeScreen)
                        .transition(.opacity.animation(.easeInOut(duration: 0.5)))
                } else {
                    HomeView(modelContext: sharedModelContainer.mainContext)
                        .transition(.opacity.animation(.easeInOut(duration: 0.5)))
                }
            }
            .preferredColorScheme(.dark)
            .alert("Não foi possível abrir seus dados", isPresented: $mostrarAvisoPersistencia) {
                Button("Entendi") {}
            } message: {
                Text("O CashUp está rodando sem salvar. O que você registrar agora será perdido ao fechar o app. Tente reinstalar ou entre em contato com o suporte.")
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
