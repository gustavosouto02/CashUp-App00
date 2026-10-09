import SwiftData
import SwiftUI

@main
struct CashUpApp: App {
    let sharedModelContainer: ModelContainer
    @State private var isShowingWelcomeScreen: Bool = true

    init() {
        let isUITesting = ProcessInfo.processInfo.arguments.contains("--uitesting")
        _isShowingWelcomeScreen = State(initialValue: !isUITesting)
        sharedModelContainer = Self.makeContainer(inMemory: isUITesting)
    }

    static func makeContainer(inMemory: Bool) -> ModelContainer {
        let schema = Schema([
            CategoriaModel.self,
            SubcategoriaModel.self,
            ExpenseModel.self,
            CategoriaPlanejadaModel.self,
            SubcategoriaPlanejadaModel.self,
        ])
        do {
            return try ModelContainer(
                for: schema,
                configurations: ModelConfiguration(schema: schema, isStoredInMemoryOnly: inMemory)
            )
        } catch {
            CashUpLogger.persistence.critical("Container persistente falhou: \(error.localizedDescription)")
            do {
                return try ModelContainer(
                    for: schema,
                    configurations: ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
                )
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
        }
        .modelContainer(sharedModelContainer)
    }
}
