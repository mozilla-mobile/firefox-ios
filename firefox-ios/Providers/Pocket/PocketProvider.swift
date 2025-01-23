// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import Storage

protocol PocketStoriesProviding {
    typealias StoryResult = Swift.Result<[PocketFeedStory], Error>

    func fetchStories(items: Int) async throws -> [PocketFeedStory]
}

extension PocketStoriesProviding {
    func fetchStories(items: Int) async throws -> [PocketFeedStory] {
        return try await fetchStories(items: items)
    }
}

class PocketProvider: PocketStoriesProviding, FeatureFlaggable, URLCaching {
    private let pocketEnvAPIKey = "PocketEnvironmentAPIKey"

    private static let SupportedLocales = ["en_CA", "en_US", "en_GB", "en_ZA", "de_DE", "de_AT", "de_CH"]

    private let pocketGlobalFeed: String
    private var prefs: Prefs

    static let GlobalFeed = "https://getpocket.cdn.mozilla.net/v3/firefox/global-recs"
    static let MoreStoriesURL = {
        switch Locale.current.identifier {
        case "de_DE":
            return URL(string: "https://getpocket.com/de/explore?src=ff_ios")!
        default:
            return URL(string: "https://getpocket.com/explore?src=ff_ios&cdn=0")!
        }
    }()

    // Allow endPoint to be overridden for testing
    init(endPoint: String = PocketProvider.GlobalFeed,
         prefs: Prefs) {
        self.pocketGlobalFeed = endPoint
        self.prefs = prefs
    }

    var urlCache: URLCache {
        return URLCache.shared
    }

    private lazy var urlSession = makeURLSession(
        userAgent: UserAgent.defaultClientUserAgent,
        configuration: URLSessionConfiguration.defaultMPTCP
    )

    private lazy var pocketKey: String? = {
        return Bundle.main.object(forInfoDictionaryKey: pocketEnvAPIKey) as? String
    }()

    enum Error: Swift.Error {
        case failure
    }

    // Fetch items from the global pocket feed
    func fetchStories(items: Int) async throws -> [PocketFeedStory] {
        let isFeatureEnabled = prefs.boolForKey(PrefsKeys.UserFeatureFlagPrefs.ASPocketStories) ?? true
        let isCurrentLocaleSupported = PocketProvider.islocaleSupported(Locale.current.identifier)

        // Check if we should use mock data
        if shouldUseMockData {
            return try await getMockDataFeed(count: items)
        }

        // Ensure the feature is enabled and current locale is supported
        guard isFeatureEnabled, isCurrentLocaleSupported else {
            throw Error.failure
        }

        // Note: Global feed is restricted to specific locale and feature availability
        return try await getGlobalFeed(items: items)
    }

    private func getGlobalFeed(items: Int) async throws -> [PocketFeedStory] {
        guard let request = createGlobalFeedRequest(items: items) else {
            throw Error.failure
        }

        if let cachedResponse = findCachedResponse(for: request),
           let items = cachedResponse["recommendations"] as? [[String: Any]] {
            return PocketFeedStory.parseJSON(list: items)
        }

        let (data, response) = try await urlSession.data(for: request)

        guard let response = validatedHTTPResponse(response, contentType: "application/json") else {
            throw Error.failure
        }

        self.cache(response: response, for: request, with: data)

        let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any]
        guard let items = json?["recommendations"] as? [[String: Any]] else {
            throw Error.failure
        }

        return PocketFeedStory.parseJSON(list: items)
    }

    // Returns nil if the locale is not supported
    static func islocaleSupported(_ locale: String) -> Bool {
        return PocketProvider.SupportedLocales.contains(locale)
    }

    // Create the URL request to query the Pocket API. The max items that the query can return is 20
    private func createGlobalFeedRequest(items: Int = 2) -> URLRequest? {
        guard items > 0 && items <= 20 else { return nil }

        let locale = Locale.current.identifier
        let pocketLocale = locale.replacingOccurrences(of: "_", with: "-")
        var params = [
            URLQueryItem(
                name: "count",
                value: String(items)
            ),
            URLQueryItem(name: "locale_lang", value: pocketLocale),
            URLQueryItem(name: "version", value: "3")
        ]
        if let pocketKey = pocketKey {
            params.append(URLQueryItem(name: "consumer_key", value: pocketKey))
        }

        guard let feedURL = URL(
            string: pocketGlobalFeed,
            invalidCharacters: false
        )?.withQueryParams(params) else { return nil }

        return URLRequest(url: feedURL, cachePolicy: .reloadIgnoringCacheData, timeoutInterval: 5)
    }

    private var shouldUseMockData: Bool {
        guard let pocketKey = pocketKey else {
            return featureFlags.isCoreFeatureEnabled(.useMockData) ? true : false
        }

        return featureFlags.isCoreFeatureEnabled(.useMockData) && pocketKey.isEmpty
    }

    private func getMockDataFeed(count: Int = 2) async throws -> [PocketFeedStory] {
        guard let path = Bundle(for: type(of: self)).path(forResource: "pocketglobalfeed", ofType: "json"),
              let data = try? Data(contentsOf: URL(fileURLWithPath: path))
        else {
            throw Error.failure
        }

        let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any]
        guard let items = json?["recommendations"] as? [[String: Any]] else {
            throw Error.failure
        }

        return Array(PocketFeedStory.parseJSON(list: items).prefix(count))
    }
}
