import Cocoa
import Foundation

// MARK: Bot Module

/// Define the bot module to use
let botModule: Module = Modules.stringEncrypter

// MARK: Twitter API

/// For Swifter auth callbacks
let twitterUrlScheme: String = "swifter"

/// Twitter account ID for Bot (optional)
let twitterAccountId: String = "89813832"

/// For Swifter auth callbacks
let twitterCallbackUrl: String = "\(twitterUrlScheme)://success"

// TODO: Persist this in keychain instead
var twitterKey: String? {
    get { return UserDefaults.standard.string(forKey: "twitter-api-key") }
    set { UserDefaults.standard.set(newValue, forKey: "twitter-api-key") }
}

// TODO: Persist this in keychain instead
var twitterSecret: String? {
    get { return UserDefaults.standard.string(forKey: "twitter-api-secret") }
    set { UserDefaults.standard.set(newValue, forKey: "twitter-api-secret") }
}

// MARK: User Interface

/// Green dot
let botAuthorizedImage: NSImage = NSImage(named: "NSStatusAvailable")!

/// Red dot
let botUnauthorizedImage: NSImage = NSImage(named: "NSStatusUnavailable")!
