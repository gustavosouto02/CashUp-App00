import Foundation

protocol TipsRepositoryProtocol: AnyObject {
    func loadEducationalTips() -> [Tip]
}
