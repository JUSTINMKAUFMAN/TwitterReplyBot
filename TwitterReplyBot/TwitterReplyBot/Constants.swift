import Cocoa
import Foundation

// MARK: Twitter

let twitterUrlScheme: String = "swifter"
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
