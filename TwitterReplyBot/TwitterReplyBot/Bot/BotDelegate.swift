import Foundation

/// Conform to this protocol to receive updates from the bot
/// (e.g. in your ViewController to display a list of responses)
protocol BotDelegate {
    func botDidChangeStatus(_ isAuthorized: Bool)
    func botDidSync(_ count: Int)
    func botDidUpdate(_ tweets: [Tweet])
}
