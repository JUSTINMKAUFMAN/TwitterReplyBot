import Foundation

class Bot {
    var delegate: BotDelegate?

    private let module: Module
    private let ignoredTweetIds: [String]
    private let observingThread: String?
    private let pollInterval: TimeInterval
    private let logToConsole: Bool
    private let twitter: Twitter

    private var lastRetrievedId: String?
    private var syncCounter: Int = 0
    private var tweets: [Tweet] = []
    private var isShuttingDown: Bool = false

    private var isAuthorized: Bool = false {
        didSet { delegate?.botDidChangeStatus(isAuthorized) }
    }

    private var processingCount: Int = 0 {
        didSet { if processingCount == 0 { onProcessingComplete() } }
    }

    init(key: String,
         secret: String,
         module: Module,
         pollInterval: TimeInterval,
         logToConsole: Bool = false) {
        twitter = Twitter(consumerKey: key, consumerSecret: secret)
        observingThread = module.thread
        ignoredTweetIds = module.blacklist
        self.module = module
        self.pollInterval = pollInterval
        self.logToConsole = logToConsole
    }

    func start() {
        guard !isShuttingDown else { isShuttingDown = false; return }

        twitter.authorize(
            withCallback: URL(string: twitterCallbackUrl)!,
            success: { [unowned self] _, _ in self.isAuthorized = true; self.poll() },
            failure: { [unowned self] _ in self.isAuthorized = false; self.authAfterInterval() }
        )
    }

    func stop() {
        isShuttingDown = true
    }

    private func poll() {
        // Check shutdown flag
        guard !isShuttingDown else { isShuttingDown = false; return }

        // Increment sync counter
        syncCounter += 1

        // Poll for new replies
        twitter.getAllMentions(
            in: observingThread,
            sinceID: lastRetrievedId,
            success: { [unowned self] rawReplies in
                // Filter replies to replies (only want top-level replies)
                let replies = rawReplies.filter {
                    $0.mentions.count == 1 &&
                        $0.mentions.filter { mention in mention.contains(self.module.handle) }.isEmpty == false &&
                        !self.ignoredTweetIds.contains($0.id)
                }

                // Store latest ID to start next search from there
                if let lastId = replies.first?.id { self.lastRetrievedId = lastId }

                // Log status intermittently
                if !replies.isEmpty, self.logToConsole {
                    print("[\(self.syncCounter)] Detected \(replies.count) New Tweet\(replies.count > 1 ? "s" : "")")
                }

                // Notify delegate of new sync count
                self.delegate?.botDidSync(self.syncCounter)

                // Add new tweets to store
                let newTweets = replies.filter { rp in self.tweets.filter { $0.id != rp.id }.isEmpty }.map { $0.toTweet }
                self.tweets = self.tweets + newTweets.sorted { $0.id > $1.id }

                // Update processing count
                self.processingCount = replies.count

                // Process each new reply
                replies.forEach { [unowned self] reply in
                    self.process(reply) { _ in self.processingCount -= 1 }
                }
            },
            failure: { [unowned self] _ in self.pollAfterInterval() }
        )
    }
}

private extension Bot {
    func process(_ reply: Reply, _ completion: @escaping (Bool) -> Void) {
        twitter.getTweetReplies(
            for: reply.id,
            toUser: reply.authorHandle,
            success: { rawRereplies in
                let rereplies: [Reply] = rawRereplies.filter { $0.authorHandle == self.module.handle }
                if !rereplies.isEmpty {
                    if let index = self.tweets.firstIndex(where: { $0.id == reply.id }) {
                        self.tweets[index].response = rereplies[0].text
                    }
                    completion(true)
                } else {
                    // Process the reply
                    self.module.output(for: reply) { result in
                        self.twitter.postTweet(
                            status: result,
                            inReplyToStatusID: reply.id,
                            autoPopulateReplyMetadata: true,
                            success: { success in
                                if self.logToConsole { print("\nBOT SUCCESS:\n\(success)\n\n") }

                                if let index = self.tweets.firstIndex(where: { $0.id == reply.id }) {
                                    self.tweets[index].response = result
                                } else {
                                    let tweet = reply.toTweet
                                    tweet.response = result
                                    self.tweets.insert(tweet, at: 0)
                                }

                                completion(true)
                            },
                            failure: { error in
                                if self.logToConsole { print("\nBOT FAILED:\n\(error)\n\n") }
                                completion(false)
                            }
                        )
                    }
                }
            },
            failure: { _ in
                if self.logToConsole { print("Error retrieving re-replies to Tweet ID '\(reply.id)' from \(reply.authorHandle)") }
                completion(false)
            }
        )
    }

    func authAfterInterval() {
        DispatchQueue.main.asyncAfter(
            deadline: .now() + pollInterval,
            execute: { [weak self] in self?.start() }
        )
    }

    func pollAfterInterval() {
        DispatchQueue.main.asyncAfter(
            deadline: .now() + pollInterval,
            execute: { [weak self] in self?.poll() }
        )
    }

    func onProcessingComplete() {
        delegate?.botDidUpdate(tweets)
        pollAfterInterval()
    }

    func moduleValidation() {
        module.validate()
    }
}
