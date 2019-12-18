import Cocoa
import Foundation

// MARK: Twitter

let twitterUrlScheme: String = "twitter"
let twitterAccountId: String = "89813832"
let twitterCallbackUrl: String = "\(twitterUrlScheme)://success"

var twitterKey: String? {
    get { return UserDefaults.standard.string(forKey: "twitter-api-key") }
    set { UserDefaults.standard.set(newValue, forKey: "twitter-api-key") }
}

var twitterSecret: String? {
    get { return UserDefaults.standard.string(forKey: "twitter-api-secret") }
    set { UserDefaults.standard.set(newValue, forKey: "twitter-api-secret") }
}

// MARK: Interface

let botAuthorizedImage: NSImage = NSImage(named: "NSStatusAvailable")!
let botUnauthorizedImage: NSImage = NSImage(named: "NSStatusUnavailable")!

// MARK: Validation

let timeoutCode: String =
    """
    import Foundation

    var count: Int = 0

    func testA() {
    while (count != -1) {
    count += 1
    }
    }

    testA()

    print("Count: \\(count)")
    """

let basicCode: String =
    """
    import Foundation

    func tester(_ string: String) -> String {
    return "Test Success: \\(string)"
    }

    let test: String = "SwiftCoderunner"

    print(tester(test))
    """

let timeoutReply = Reply(
    id: UUID().uuidString,
    text: timeoutCode,
    authorId: twitterAccountId,
    authorHandle: "SwiftCoderunner",
    timestamp: "39479234762"
)

let basicReply = Reply(
    id: UUID().uuidString,
    text: basicCode,
    authorId: twitterAccountId,
    authorHandle: "JUSTINMKAUFMAN",
    timestamp: "39479239340"
)
