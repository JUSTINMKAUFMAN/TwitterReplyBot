import Cocoa

/// Define a bot module to use
let botModule: Module = Modules.coderunner

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        configureURLScheme()
    }
}

extension AppDelegate {
    private func configureURLScheme() {
        NSAppleEventManager.shared().setEventHandler(
            self,
            andSelector: #selector(AppDelegate.handleEvent(_:withReplyEvent:)),
            forEventClass: AEEventClass(kInternetEventClass),
            andEventID: AEEventID(kAEGetURL)
        )

        LSSetDefaultHandlerForURLScheme(
            twitterUrlScheme as CFString,
            Bundle.main.bundleIdentifier! as CFString
        )
    }

    @objc func handleEvent(_ event: NSAppleEventDescriptor!, withReplyEvent: NSAppleEventDescriptor!) {
        guard let callbackUrl = URL(string: twitterCallbackUrl) else { return }
        guard let urlString = event.paramDescriptor(forKeyword: AEKeyword(keyDirectObject))?.stringValue else { return }
        guard let url = URL(string: urlString) else { return }
        Twitter.handleOpenURL(url, callbackURL: callbackUrl)
    }

    func clearPersistentData() {
        let domain = Bundle.main.bundleIdentifier!
        UserDefaults.standard.removePersistentDomain(forName: domain)
        UserDefaults.standard.synchronize()
    }
}
