import Foundation

struct OnboardingPage: Identifiable, Equatable {
    let id: Int
    let titulo: String
    let mensagem: String
    let icone: String

    static let padrao: [OnboardingPage] = [
        OnboardingPage(
            id: 0,
            titulo: "Registre em segundos",
            mensagem: "Valor, categoria e pronto. Sem conta, sem internet, sem complicação.",
            icone: "bolt.fill"
        ),
        OnboardingPage(
            id: 1,
            titulo: "Planeje o mês",
            mensagem: "Defina tetos por subcategoria e acompanhe em tempo real o que ainda sobra para gastar.",
            icone: "chart.pie.fill"
        ),
        OnboardingPage(
            id: 2,
            titulo: "Seus dados são seus",
            mensagem: "Nada sai do seu iPhone. Sem servidores externos e com proteção biométrica nativa.",
            icone: "faceid"
        )
    ]
}
