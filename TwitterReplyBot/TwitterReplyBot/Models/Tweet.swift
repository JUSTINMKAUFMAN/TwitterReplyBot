import Cocoa

public class Tweet: NSObject {
    @objc public dynamic let id: String
    @objc public dynamic let userId: String
    @objc public dynamic let timestamp: String
    @objc public dynamic let user: String
    @objc public dynamic let text: String
    @objc public dynamic var response: String

    public init(id: String,
                userId: String,
                timestamp: String,
                user: String,
                text: String,
                response: String = "") {
        self.id = id
        self.userId = userId
        self.timestamp = timestamp
        self.user = user
        self.text = text
        self.response = response
        super.init()
    }
}
