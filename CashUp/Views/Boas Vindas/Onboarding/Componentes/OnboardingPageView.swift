import SwiftUI

struct OnboardingPageView: View {
    let page: OnboardingPage
    @ObservedObject var settingsViewModel: SettingsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            headerSection
                .padding(.horizontal, 24)
                .padding(.top, 12)

            cardContent
                .padding(.horizontal, 20)

            Spacer(minLength: 0)
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 10) {

            Text(LocalizedStringKey(page.titulo))
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(.white)
                .lineLimit(2)

            Text(LocalizedStringKey(page.mensagem))
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(Color.white.opacity(0.72))
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder
    private var cardContent: some View {
        switch page.id {
        case 0:
            MotionExpenseSimulationCard()
        case 1:
            PlanningSimulationCard()
        case 2:
            PrivacySecurityCard(settingsViewModel: settingsViewModel)
        default:
            EmptyView()
        }
    }
}
