import SwiftUI

struct OnboardingView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @ObservedObject var settingsViewModel: SettingsViewModel
    let onConcluir: () -> Void

    var body: some View {
        ZStack {
            Color(red: 16/255, green: 22/255, blue: 28/255)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                TabView(selection: $viewModel.paginaAtual) {
                    ForEach(viewModel.paginas) { pagina in
                        OnboardingPageView(
                            page: pagina,
                            settingsViewModel: settingsViewModel
                        )
                        .tag(pagina.id)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                OnboardingPageIndicator(
                    totalPaginas: viewModel.paginas.count,
                    paginaAtual: viewModel.paginaAtual
                )
                .padding(.bottom, 8)

                OnboardingActionsBar(
                    isUltimaPagina: viewModel.isUltimaPagina,
                    onPular: {
                        viewModel.pular()
                        onConcluir()
                    },
                    onAvancar: {
                        withAnimation {
                            viewModel.avancar()
                        }
                    },
                    onConcluir: {
                        viewModel.concluir()
                        onConcluir()
                    }
                )
            }
        }
        .errorAlert($settingsViewModel.errorMessage)
    }
}
