import SwiftUI

struct OnboardingActionsBar: View {
    let isUltimaPagina: Bool
    let onPular: () -> Void
    let onAvancar: () -> Void
    let onConcluir: () -> Void

    var body: some View {
        HStack {
            if isUltimaPagina {
                Button(action: onConcluir) {
                    Text("Começar a Usar")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color(red: 0/255, green: 112/255, blue: 244/255))
                        .clipShape(Capsule())
                }
                .accessibilityIdentifier("onboardingStartButton")
            } else {
                Button(action: onPular) {
                    Text("Pular")
                        .font(.body.weight(.medium))
                        .foregroundStyle(Color.white.opacity(0.65))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                }
                .accessibilityIdentifier("onboardingSkipButton")

                Spacer()

                Button(action: onAvancar) {
                    HStack(spacing: 8) {
                        Text("Próximo")
                            .font(.headline.weight(.semibold))
                        Image(systemName: "arrow.right")
                            .font(.subheadline.bold())
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 26)
                    .padding(.vertical, 14)
                    .background(Color(red: 0/255, green: 112/255, blue: 244/255))
                    .clipShape(Capsule())
                }
                .accessibilityIdentifier("onboardingNextButton")
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 20)
        .animation(.easeInOut(duration: 0.25), value: isUltimaPagina)
    }
}
