import Foundation
@testable import CashUp

final class MockTipsRepository: TipsRepositoryProtocol {
    var tipsToReturn: [Tip] = []

    init(tips: [Tip] = []) {
        self.tipsToReturn = tips
    }

    func loadEducationalTips() -> [Tip] {
        tipsToReturn
    }
}
