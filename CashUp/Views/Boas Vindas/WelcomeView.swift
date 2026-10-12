import SwiftUI

struct WelcomeView: View {
    @Binding var isShowingWelcomeScreen: Bool

    var body: some View {
        ZStack {
            Color(red: 16/255, green: 22/255, blue: 28/255)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Spacer()

                Image("IconCashUp")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 180, height: 180)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                    .padding(.bottom, 25)

                Text("Bem-vindo ao CashUp!")
                    .font(Font.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text("Suas finanças, sob seu controle.")
                    .font(Font.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundColor(.gray.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                Spacer()
                Spacer()
            }
            .padding()
        }
        .task {
            try? await Task.sleep(for: .seconds(2.5))
            guard !Task.isCancelled else { return }
            withAnimation {
                isShowingWelcomeScreen = false
            }
        }
    }
}
