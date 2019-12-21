import Cocoa

class BotViewController: NSViewController {
    /// User interface elements
    @IBOutlet var keyField: NSTextField!
    @IBOutlet var secretField: NSTextField!
    @IBOutlet var updateButton: NSButton!
    @IBOutlet var syncLabel: NSTextField!
    @IBOutlet var statusImage: NSImageView!
    @IBOutlet var tableView: NSTableView!

    /// Tweets datasource
    @objc dynamic var tweets: [Tweet] = []

    private var bot: Bot? {
        didSet { bot?.delegate = self }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.usesAutomaticRowHeights = false
        tableView.delegate = self
        restoreState()
    }

    @IBAction func updateAction(_ sender: NSButton) {
        let key = keyField.stringValue
        let secret = secretField.stringValue

        guard !key.isEmpty, !secret.isEmpty else { return }
        twitterKey = key
        twitterSecret = secret

        bot = Bot(
            key: key,
            secret: secret,
            module: botModule,
            pollInterval: 15.0
        )
        bot?.start()
    }

    private func restoreState() {
        if let key = twitterKey { keyField.stringValue = key }
        if let secret = twitterSecret { secretField.stringValue = secret }
        updateAction(updateButton)
    }
}

// MARK: BotDelegate

extension BotViewController: BotDelegate {
    func botDidChangeStatus(_ isAuthorized: Bool) {
        DispatchQueue.main.async { [weak self] in
            self?.statusImage.image = isAuthorized ? botAuthorizedImage : botUnauthorizedImage
        }
    }

    func botDidSync(_ count: Int) {
        DispatchQueue.main.async { [weak self] in
            self?.syncLabel.stringValue = "\(count)"
        }
    }

    func botDidUpdate(_ tweets: [Tweet]) {
        DispatchQueue.main.async { [weak self] in
            self?.tweets = tweets
        }
    }
}

// MARK: NSTableViewDelegate

extension BotViewController: NSTableViewDelegate {
    func tableViewColumnDidResize(_ notification: Notification) {
        let allIndexes = IndexSet(integersIn: 0 ..< tableView.numberOfRows)
        tableView.noteHeightOfRows(withIndexesChanged: allIndexes)
        tableView.reloadData()
    }

    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        let model = tweets[row]
        let font = NSFont.systemFont(ofSize: NSFont.systemFontSize)

        let userWidth = tableView.tableColumns[0].width
        let textWidth = tableView.tableColumns[1].width
        let responseWidth = tableView.tableColumns[2].width

        let userHeight = model.user.height(width: userWidth, font: font)
        let textHeight = model.text.height(width: textWidth, font: font)
        let responseHeight = model.text.height(width: responseWidth, font: font)

        return max(userHeight, textHeight, responseHeight)
    }
}
