import Foundation

public struct Reply {
    public let id: String
    public let text: String
    public let authorId: String
    public let authorHandle: String
    public let timestamp: String
    public let mentions: [String]
    public let inReplyToId: String?

    public init(id: String,
                text: String,
                authorId: String,
                authorHandle: String,
                timestamp: String,
                mentions: [String] = [],
                inReplyToId: String? = nil) {
        self.id = id
        self.text = text
        self.authorId = authorId
        self.authorHandle = authorHandle
        self.timestamp = timestamp
        self.mentions = mentions
        self.inReplyToId = inReplyToId
    }
}

public extension Reply {
    var toTweet: Tweet {
        return Tweet(
            id: id,
            userId: authorId,
            timestamp: timestamp,
            user: authorHandle,
            text: text
        )
    }
}
