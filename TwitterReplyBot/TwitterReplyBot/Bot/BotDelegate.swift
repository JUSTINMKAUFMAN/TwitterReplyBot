import Foundation

protocol BotDelegate {
    func botDidChangeStatus(_ isAuthorized: Bool)
    func botDidSync(_ count: Int)
    func botDidUpdate(_ tweets: [Tweet])
}
