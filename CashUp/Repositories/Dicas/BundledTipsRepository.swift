import Foundation

final class BundledTipsRepository: TipsRepositoryProtocol {
    private let bundle: Bundle

    init(bundle: Bundle = .main) {
        self.bundle = bundle
    }

    func loadEducationalTips() -> [Tip] {
        if let url = bundle.url(forResource: "tips", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let decoded = try? JSONDecoder().decode([Tip].self, from: data) {
            return decoded
        }
        return fallbackTips
    }

    private var fallbackTips: [Tip] {
        [
            Tip(id: "tip-01",
                title: "Regra dos 3 Dias para Desejos",
                body: "Viu algo irresistível online? Coloque no carrinho e espere 72 horas. Em mais de 70% das vezes a urgência passa e você poupa sem sofrer.",
                icon: "clock.badge.checkmark.fill",
                category: .habitos,
                tag: "Autocontrole"),
            Tip(id: "tip-02",
                title: "Delivery: O Ralo Silencioso",
                body: "Duas refeições por aplicativo a menos na semana costumam representar mais de R$ 300,00 poupados no fim do mês. Cozinhar em lote no domingo salva seu bolso.",
                icon: "takeoutbag.and.cup.and.straw.fill",
                category: .economia,
                tag: "Alimentação"),
            Tip(id: "tip-03",
                title: "Auditoria de Assinaturas Recorrentes",
                body: "Revise extratos de cartões a cada trimestre. Serviços de streaming e assinaturas esquecidas acumulam valores expressivos ao longo de 1 ano.",
                icon: "rectangle.stack.badge.play.fill",
                category: .orcamento,
                tag: "Fixos"),
            Tip(id: "tip-04",
                title: "Pague a Si Mesmo Primeiro",
                body: "Não guarde o que sobra após os gastos: defina o valor da sua poupança ou reserva e transfira logo no dia em que o salário ou rendimento cai.",
                icon: "arrow.down.right.and.arrow.up.left",
                category: .renda,
                tag: "Disciplina"),
            Tip(id: "tip-05",
                title: "Divisão 50/30/20 Descomplicada",
                body: "Mantenha até 50% para necessidades básicas, 30% para estilo de vida e lazer, e garanta 20% para quitar dívidas ou construir patrimônio.",
                icon: "chart.pie.fill",
                category: .orcamento,
                tag: "Planejamento"),
            Tip(id: "tip-06",
                title: "Evite Parcelamentos Menores que 3x",
                body: "Se a compra não couber à vista e não for um bem durável essencial, parcelar em 2x ou 3x só amarra o limite do seu mês que vem com coisas que já passaram.",
                icon: "creditcard.and.123",
                category: .habitos,
                tag: "Cartão"),
            Tip(id: "tip-07",
                title: "Construa sua Reserva de Paz",
                body: "Ter o equivalente a 3 a 6 meses do seu custo fixo aplicado em liquidez diária evita que você precise recorrer a juros caros em emergências.",
                icon: "shield.lefthalf.filled",
                category: .renda,
                tag: "Segurança"),
            Tip(id: "tip-08",
                title: "Supermercado com Lista e Estômago Cheio",
                body: "Fazer compras com fome ou sem conferir o que já tem na despensa aumenta as compras por impulso em até 40%.",
                icon: "cart.fill",
                category: .economia,
                tag: "Rotina")
        ]
    }
}
