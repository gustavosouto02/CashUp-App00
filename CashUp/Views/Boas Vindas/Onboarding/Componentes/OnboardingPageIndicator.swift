import SwiftUI

struct OnboardingPageIndicator: View {
    let totalPaginas: Int
    let paginaAtual: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalPaginas, id: \.self) { indice in
                Capsule()
                    .fill(indice == paginaAtual ? Color.white : Color.white.opacity(0.3))
                    .frame(width: indice == paginaAtual ? 22 : 7, height: 7)
                    .animation(.spring(response: 0.35, dampingFraction: 0.7), value: paginaAtual)
            }
        }
        .accessibilityIdentifier("onboardingPageIndicator")
    }
}
