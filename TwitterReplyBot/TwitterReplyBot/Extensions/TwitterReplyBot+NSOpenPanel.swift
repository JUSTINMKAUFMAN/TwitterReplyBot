import Cocoa
import Foundation

func selectDirectory(_ completion: (String?) -> Void) {
    let openPanel = NSOpenPanel()
    openPanel.title = "Select directory"
    openPanel.showsHiddenFiles = false
    openPanel.canChooseFiles = false
    openPanel.canChooseDirectories = true
    openPanel.canCreateDirectories = false
    openPanel.allowsMultipleSelection = false
    openPanel.directoryURL = URL(fileURLWithPath: "~/")

    if openPanel.runModal() == .OK,
        let workingUrl = openPanel.url {
        let path = "\(workingUrl.path)"
        completion(path)
    } else {
        completion(nil)
    }
}
