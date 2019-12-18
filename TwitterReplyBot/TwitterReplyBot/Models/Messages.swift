import Foundation

// MARK: Message

public struct Message {
    public let id: String
    public let text: String
    public let sender: String
    public let recipient: String
    public let timestamp: String

    public var nonOwnerAccountId: String {
        return recipient == twitterAccountId ? sender : recipient
    }
}

public struct Messages: Codable {
    public let events: [Event]
    public let apps: [String: App]
    public let nextCursor: String

    public enum CodingKeys: String, CodingKey {
        case events, apps
        case nextCursor = "next_cursor"
    }

    public init(events: [Event], apps: [String: App], nextCursor: String) {
        self.events = events
        self.apps = apps
        self.nextCursor = nextCursor
    }

    public var messages: [Message] {
        return events.map { event in
            return Message(
                id: event.id,
                text: event.messageCreate.messageData.text,
                sender: event.messageCreate.senderID,
                recipient: event.messageCreate.target.recipientID,
                timestamp: event.createdTimestamp
            )
        }
    }
}

// MARK: App

public struct App: Codable {
    public let url: String
    public let name, id: String

    public init(url: String, name: String, id: String) {
        self.url = url
        self.name = name
        self.id = id
    }
}

// MARK: Event

public struct Event: Codable {
    public let messageCreate: MessageCreate
    public let type: TypeEnum
    public let createdTimestamp, id: String

    public enum CodingKeys: String, CodingKey {
        case messageCreate = "message_create"
        case type
        case createdTimestamp = "created_timestamp"
        case id
    }

    public init(messageCreate: MessageCreate, type: TypeEnum, createdTimestamp: String, id: String) {
        self.messageCreate = messageCreate
        self.type = type
        self.createdTimestamp = createdTimestamp
        self.id = id
    }
}

// MARK: MessageCreate

public struct MessageCreate: Codable {
    public let sourceAppID: String?
    public let target: Target
    public let messageData: MessageData
    public let senderID: String

    public enum CodingKeys: String, CodingKey {
        case sourceAppID = "source_app_id"
        case target
        case messageData = "message_data"
        case senderID = "sender_id"
    }

    public init(sourceAppID: String?, target: Target, messageData: MessageData, senderID: String) {
        self.sourceAppID = sourceAppID
        self.target = target
        self.messageData = messageData
        self.senderID = senderID
    }
}

// MARK: MessageData

public struct MessageData: Codable {
    public let entities: Entities
    public let text: String

    public init(entities: Entities, text: String) {
        self.entities = entities
        self.text = text
    }
}

// MARK: Entities

public struct Entities: Codable {
    public let urls: [URLElement]
    public let hashtags, symbols, userMentions: [JSONAny]

    public enum CodingKeys: String, CodingKey {
        case urls, hashtags, symbols
        case userMentions = "user_mentions"
    }

    public init(urls: [URLElement], hashtags: [JSONAny], symbols: [JSONAny], userMentions: [JSONAny]) {
        self.urls = urls
        self.hashtags = hashtags
        self.symbols = symbols
        self.userMentions = userMentions
    }
}

// MARK: URLElement

public struct URLElement: Codable {
    public let url, expandedURL: String
    public let indices: [Int]
    public let displayURL: String

    public enum CodingKeys: String, CodingKey {
        case url
        case expandedURL = "expanded_url"
        case indices
        case displayURL = "display_url"
    }

    public init(url: String, expandedURL: String, indices: [Int], displayURL: String) {
        self.url = url
        self.expandedURL = expandedURL
        self.indices = indices
        self.displayURL = displayURL
    }
}

// MARK: Target

public struct Target: Codable {
    public let recipientID: String

    public enum CodingKeys: String, CodingKey {
        case recipientID = "recipient_id"
    }

    public init(recipientID: String) {
        self.recipientID = recipientID
    }
}

public enum TypeEnum: String, Codable {
    case messageCreate = "message_create"
}
