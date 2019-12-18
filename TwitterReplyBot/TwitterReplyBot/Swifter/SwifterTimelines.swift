import Foundation

public extension Swifter {
    private func getTimeline(at path: String,
                             parameters: [String: Any] = [:],
                             count: Int? = 800,
                             sinceID: String? = nil,
                             maxID: String? = nil,
                             trimUser: Bool? = nil,
                             excludeReplies: Bool? = false,
                             includeRetweets: Bool? = true,
                             contributorDetails: Bool? = true,
                             includeEntities: Bool? = true,
                             tweetMode: TweetMode = .extended,
                             success: SuccessHandler? = nil,
                             failure: FailureHandler? = nil) {
        var params = parameters
        params["count"] ??= count
        params["since_id"] ??= sinceID
        params["max_id"] ??= maxID
        params["trim_user"] ??= trimUser
        params["exclude_replies"] ??= excludeReplies
        params["include_rts"] ??= includeRetweets
        params["contributor_details"] ??= contributorDetails
        params["include_entities"] ??= includeEntities
        params["tweet_mode"] ??= tweetMode.stringValue

        getJSON(
            path: path,
            baseURL: .api,
            parameters: params,
            success: { json, _ in success?(json) },
            failure: failure
        )
    }

    /**
     GET    statuses/mentions_timeline
     Returns Tweets (*: mentions for the user)

     Returns the 20 most recent mentions (tweets containing a users's @screen_name) for the authenticating user.

     The timeline returned is the equivalent of the one seen when you view your mentions on twitter.com.

     This method can only return up to 800 tweets.
     */
    func getMentionsTimelineTweets(count: Int? = nil,
                                   sinceID: String? = nil,
                                   maxID: String? = nil,
                                   trimUser: Bool? = nil,
                                   contributorDetails: Bool? = nil,
                                   includeEntities: Bool? = nil,
                                   tweetMode: TweetMode = TweetMode.extended,
                                   success: SuccessHandler? = nil,
                                   failure: FailureHandler?) {
        getTimeline(
            at: "statuses/mentions_timeline.json",
            parameters: [:],
            count: count,
            sinceID: sinceID,
            maxID: maxID,
            trimUser: trimUser,
            contributorDetails: contributorDetails,
            includeEntities: includeEntities,
            tweetMode: tweetMode,
            success: success,
            failure: failure
        )
    }

    func getTweetReplies(for id: String,
                         toUser: String,
                         success: RepliesSuccessHandler? = nil,
                         failure: FailureHandler?) {
        searchTweet(
            using: toUser,
            sinceID: id,
            success: { json, _ in
                guard let array = json.array else { fatalError() }
                let repliesArray = array.filter { ($0["in_reply_to_status_id_str"].string ?? "") == id }
                let mentions: [Reply] = repliesArray.map { tweet in
                    let text: String = tweet["full_text"].string ?? "ERROR"
                    return Reply(
                        id: tweet["id_str"].string ?? "ERROR",
                        text: text.strippingMentions,
                        authorId: tweet["user"]["id_str"].string ?? "ERROR",
                        authorHandle: tweet["user"]["screen_name"].string ?? "ERROR",
                        timestamp: tweet["created_at"].string ?? "ERROR",
                        mentions: text.mentions,
                        inReplyToId: tweet["in_reply_to_status_id_str"].string
                    )
                }
                success?(mentions)
            },
            failure: { error in failure?(error) }
        )
    }

    func getAllMentions(in tweetID: String? = nil,
                        count: Int? = 800,
                        sinceID: String? = nil,
                        maxID: String? = nil,
                        trimUser: Bool? = nil,
                        contributorDetails: Bool? = nil,
                        includeEntities: Bool? = nil,
                        tweetMode: TweetMode = TweetMode.extended,
                        success: RepliesSuccessHandler? = nil,
                        failure: FailureHandler?) {
        getTimeline(
            at: "statuses/mentions_timeline.json",
            parameters: [:],
            count: count,
            sinceID: sinceID,
            maxID: maxID,
            trimUser: trimUser,
            contributorDetails: contributorDetails,
            includeEntities: includeEntities,
            tweetMode: tweetMode,
            success: { json in
                guard let array = json.array else { fatalError() }
                let tweetsArray = (tweetID == nil) ? array : array.filter { ($0["in_reply_to_status_id_str"].string ?? "") == tweetID! }
                let mentions = tweetsArray.map { tweet -> Reply in
                    let text: String = tweet["full_text"].string ?? "ERROR"
                    return Reply(
                        id: tweet["id_str"].string ?? "ERROR",
                        text: text.strippingMentions,
                        authorId: tweet["user"]["id_str"].string ?? "ERROR",
                        authorHandle: tweet["user"]["screen_name"].string ?? "ERROR",
                        timestamp: tweet["created_at"].string ?? "ERROR",
                        mentions: text.mentions,
                        inReplyToId: tweet["in_reply_to_status_id_str"].string
                    )
                }
                success?(mentions)
            },
            failure: failure
        )
    }

    /**
     GET    statuses/user_timeline
     Returns Tweets (*: tweets for the user)

     Returns a collection of the most recent Tweets posted by the user indicated by the screen_name or user_id parameters.

     User timelines belonging to protected users may only be requested when the authenticated user either "owns" the timeline or is an approved follower of the owner.

     The timeline returned is the equivalent of the one seen when you view a user's profile on twitter.com.

     This method can only return up to 3,200 of a user's most recent Tweets. Native retweets of other statuses by the user is included in this total, regardless of whether include_rts is set to false when requesting this resource.
     */
    func getTimeline(for userTag: UserTag,
                     customParam: [String: Any] = [:],
                     count: Int? = nil,
                     sinceID: String? = nil,
                     maxID: String? = nil,
                     trimUser: Bool? = nil,
                     excludeReplies: Bool? = nil,
                     includeRetweets: Bool? = nil,
                     contributorDetails: Bool? = nil,
                     includeEntities: Bool? = nil,
                     tweetMode: TweetMode = .default,
                     success: SuccessHandler? = nil,
                     failure: FailureHandler? = nil) {
        var parameters: [String: Any] = customParam
        parameters[userTag.key] = userTag.value
        getTimeline(
            at: "statuses/user_timeline.json",
            parameters: parameters,
            count: count,
            sinceID: sinceID,
            maxID: maxID,
            trimUser: trimUser,
            excludeReplies: excludeReplies,
            includeRetweets: includeRetweets,
            contributorDetails: contributorDetails,
            includeEntities: includeEntities,
            tweetMode: tweetMode,
            success: success,
            failure: failure
        )
    }

    /**
     GET    statuses/home_timeline

     Returns Tweets (*: tweets from people the user follows)

     Returns a collection of the most recent Tweets and retweets posted by the authenticating user and the users they follow. The home timeline is central to how most users interact with the Twitter service.

     Up to 800 Tweets are obtainable on the home timeline. It is more volatile for users that follow many users or follow users who tweet frequently.
     */
    func getHomeTimeline(count: Int? = 800,
                         sinceID: String? = nil,
                         maxID: String? = nil,
                         trimUser: Bool? = nil,
                         contributorDetails: Bool? = nil,
                         includeEntities: Bool? = nil,
                         tweetMode: TweetMode = TweetMode.extended,
                         success: SuccessHandler? = nil,
                         failure: FailureHandler? = nil) {
        getTimeline(
            at: "statuses/home_timeline.json",
            parameters: [:],
            count: count,
            sinceID: sinceID,
            maxID: maxID,
            trimUser: trimUser,
            contributorDetails: contributorDetails,
            includeEntities: includeEntities,
            tweetMode: tweetMode,
            success: success,
            failure: failure
        )
    }

    /**
     GET    statuses/retweets_of_me

     Returns the most recent tweets authored by the authenticating user that have been retweeted by others. This timeline is a subset of the user's GET statuses/user_timeline. See Working with Timelines for instructions on traversing timelines.
     */
    func getRetweetsOfMe(count: Int? = nil,
                         sinceID: String? = nil,
                         maxID: String? = nil,
                         trimUser: Bool? = nil,
                         contributorDetails: Bool? = nil,
                         includeEntities: Bool? = nil,
                         tweetMode: TweetMode = .default,
                         success: SuccessHandler? = nil,
                         failure: FailureHandler? = nil) {
        getTimeline(
            at: "statuses/retweets_of_me.json",
            parameters: [:],
            count: count,
            sinceID: sinceID,
            maxID: maxID,
            trimUser: trimUser,
            contributorDetails: contributorDetails,
            includeEntities: includeEntities,
            tweetMode: tweetMode,
            success: success,
            failure: failure
        )
    }
}
