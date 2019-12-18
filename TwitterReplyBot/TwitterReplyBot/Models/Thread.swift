import Foundation

public typealias DirectMessages = [Thread]

public class Thread {
    public var user: String
    public var messages: [Message]

    public init(user: String, messages: [Message]) {
        self.user = user
        self.messages = messages
    }
}
