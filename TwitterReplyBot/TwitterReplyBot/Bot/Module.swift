import Foundation

protocol Module {
    /// Twitter screen name of bot user
    var handle: String { get }

    /// Exclusive thread ID to respond to replies on (optional, if nil, bot responds to all mentions)
    var thread: String? { get }

    /// Tweet IDs to always ignore (optional)
    var blacklist: [String] { get }

    /// Generate a response for an incoming reply
    func output(for reply: Reply, _ completion: @escaping ((String) -> Void))

    /// Optionally provide a module validation method to prove it works as expected
    func validate()

    /// Required initializer
    init()
}

// MARK: Default Implementations

extension Module {
    var thread: String? { return nil }
    var blacklist: [String] { return [] }
    func validate() { assert(true) }
}
