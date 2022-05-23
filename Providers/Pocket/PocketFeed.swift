// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation
import Shared
import Storage

class Pocket: FeatureFlaggable, URLCaching {

    private class PocketError: MaybeErrorType {
        var description = "Failed to load from API"
    }

    private let PocketEnvAPIKey = "PocketEnvironmentAPIKey"

    private static let SupportedLocales = ["en_CA", "en_US", "en_GB", "en_ZA", "de_DE", "de_AT", "de_CH"]
    private let pocketGlobalFeed: String

    static let GlobalFeed = "https://getpocket.cdn.mozilla.net/v3/firefox/global-recs"
    static let MoreStoriesURL = URL(string: "https://getpocket.com/explore?src=ff_ios&cdn=0")!

    // Allow endPoint to be overriden for testing
    init(endPoint: String = Pocket.GlobalFeed) {
        self.pocketGlobalFeed = endPoint
    }

    var urlCache: URLCache {
        return URLCache.shared
    }

    lazy private var urlSession = makeURLSession(userAgent: UserAgent.defaultClientUserAgent, configuration: URLSessionConfiguration.default)

    private lazy var pocketKey: String? = {
        return Bundle.main.object(forInfoDictionaryKey: PocketEnvAPIKey) as? String
    }()

    // Fetch items from the global pocket feed
    func globalFeed(items: Int = 2) -> Deferred<[PocketFeedStory]> {
        if shouldUseMockData {
            return getMockDataFeed(count: items)
        } else {
            return getGlobalFeed(items: items)
        }
    }

    // Fetch items from the global pocket feed
    func sponsoredFeed(items: Int = 2) -> Deferred<[PocketSponsoredStory]> {
        if shouldUseMockData {
            return getMockSponsoredFeed()
        } else {
            return Deferred(value: [])
        }
    }

    private func getGlobalFeed(items: Int = 2) -> Deferred<Array<PocketFeedStory>> {
        let deferred = Deferred<Array<PocketFeedStory>>()

        guard let request = createGlobalFeedRequest(items: items) else {
            deferred.fill([])
            return deferred
        }

        if let cachedResponse = findCachedResponse(for: request), let items = cachedResponse["recommendations"] as? Array<[String: Any]> {
            deferred.fill(PocketFeedStory.parseJSON(list: items))
            return deferred
        }

        urlSession.dataTask(with: request) { (data, response, error) in
            guard let response = validatedHTTPResponse(response, contentType: "application/json"), let data = data else {
                return deferred.fill([])
            }

            self.cache(response: response, for: request, with: data)

            let json = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any]
            guard let items = json?["recommendations"] as? Array<[String: Any]> else {
                return deferred.fill([])
            }

            return deferred.fill(PocketFeedStory.parseJSON(list: items))
        }.resume()

        return deferred
    }

    // Returns nil if the locale is not supported
    static func IslocaleSupported(_ locale: String) -> Bool {
        return Pocket.SupportedLocales.contains(locale)
    }

    // Create the URL request to query the Pocket API. The max items that the query can return is 20
    private func createGlobalFeedRequest(items: Int = 2) -> URLRequest? {
        guard items > 0 && items <= 20 else {
            return nil
        }

        let locale = Locale.current.identifier
        let pocketLocale = locale.replacingOccurrences(of: "_", with: "-")
        var params = [URLQueryItem(name: "count", value: String(items)), URLQueryItem(name: "locale_lang", value: pocketLocale), URLQueryItem(name: "version", value: "3")]
        if let pocketKey = pocketKey {
            params.append(URLQueryItem(name: "consumer_key", value: pocketKey))
        }

        guard let feedURL = URL(string: pocketGlobalFeed)?.withQueryParams(params) else {
            return nil
        }

        return URLRequest(url: feedURL, cachePolicy: .reloadIgnoringCacheData, timeoutInterval: 5)
    }

    private var shouldUseMockData: Bool {
        return featureFlags.isCoreFeatureEnabled(.useMockData) && (pocketKey == "" || pocketKey == nil)
    }

    private func getMockDataFeed(count: Int = 2) -> Deferred<Array<PocketFeedStory>> {
        let deferred = Deferred<Array<PocketFeedStory>>()
        let path = Bundle(for: type(of: self)).path(forResource: "pocketglobalfeed", ofType: "json")
        let data = try! Data(contentsOf: URL(fileURLWithPath: path!))

        let json = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any]
        guard let items = json?["recommendations"] as? Array<[String: Any]> else {
            deferred.fill([])
            return deferred
        }

        deferred.fill(Array(PocketFeedStory.parseJSON(list: items).prefix(count)))
        return deferred
    }

    private func getMockSponsoredFeed() -> Deferred<[PocketSponsoredStory]> {
        let deferred = Deferred<[PocketSponsoredStory]>()
        let path = Bundle(for: type(of: self)).path(forResource: "pocketsponsoredfeed", ofType: "json")
        let data = try! Data(contentsOf: URL(fileURLWithPath: path!))
        let response = try! JSONDecoder().decode(PocketSponsoredRequest.self, from: data)
        deferred.fill(response.spocs)
        return deferred
    }
}
