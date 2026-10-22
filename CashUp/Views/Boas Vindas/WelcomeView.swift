import SwiftUI

struct WelcomeView: View {
    @Binding var isShowingWelcomeScreen: Bool

    var body: some View {
        ZStack {
            Color(red: 16/255, green: 22/255, blue: 28/255)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Image("IconCashUp")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 130, height: 130)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.25), radius: 10, x: 0, y: 5)

                Text("CashUp")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
        }
        .task {
            try? await Task.sleep(for: .milliseconds(1200))
            guard !Task.isCancelled else { return }
            withAnimation(.easeInOut(duration: 0.4)) {
                isShowingWelcomeScreen = false
            }
        }
    }
}
