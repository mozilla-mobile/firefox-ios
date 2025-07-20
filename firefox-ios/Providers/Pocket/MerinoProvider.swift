// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import MozillaAppServices

protocol MerinoStoriesProviding: Sendable {
    typealias StoryResult = Swift.Result<[RecommendationDataItem], Error>

    func fetchStories(items: Int) async throws -> [RecommendationDataItem]
}

extension MerinoStoriesProviding {
    func fetchStories(items: Int) async throws -> [RecommendationDataItem] {
        return try await fetchStories(items: items)
    }
}

final class MerinoProvider: MerinoStoriesProviding, FeatureFlaggable, Sendable {
    private static let SupportedLocales = ["en_CA", "en_US", "en_GB", "en_ZA", "de_DE", "de_AT", "de_CH"]

    private let prefs: Prefs

    let MerinoServicesBaseURL = "https://merino.services.mozilla.com"

    enum Error: Swift.Error {
        case failure
    }

    // Allow endPoint to be overridden for testing
    init(
//        endPoint: String = PocketProvider.GlobalFeed,
         prefs: Prefs) {
//        self.pocketGlobalFeed = endPoint
        self.prefs = prefs
//        self.urlSession = makeURLSession(userAgent: UserAgent.defaultClientUserAgent,
//                                         configuration: URLSessionConfiguration.defaultMPTCP)
//        self.pocketKey = Bundle.main.object(forInfoDictionaryKey: pocketEnvAPIKey) as? String
    }

    func fetchStories(items: Int32) async throws -> [RecommendationDataItem] {
        let isFeatureEnabled = prefs.boolForKey(PrefsKeys.UserFeatureFlagPrefs.ASPocketStories) ?? true
        let isCurrentLocaleSupported = PocketProvider.islocaleSupported(Locale.current.identifier)

        if shouldUseMockData {
            return try await getMockDataFeed(count: items)
        }

        // Ensure the feature is enabled and current locale is supported
        guard isFeatureEnabled, isCurrentLocaleSupported else {
            throw Error.failure
        }

        return try await getFeedItems(items: items)
    }

    func getFeedItems(items: Int32) async throws -> [RecommendationDataItem] {
        do {
            let client = try CuratedRecommendationsClient(
                config: CuratedRecommendationsConfig(
                    baseHost: MerinoServicesBaseURL,
                    userAgentHeader: UserAgent.getUserAgent()
                )
            )

            let merinoRequest = CuratedRecommendationsRequest(
                // RGB what's the expecetd local here
                locale: CuratedRecommendationLocale.enUs,
                count: items
            )

            let response = try client.getCuratedRecommendations(request: merinoRequest)
            print("RGB - \(response)")
            return response.data
        } catch let error as CuratedRecommendationsApiError {
            switch error {
            case .Network(let reason):
                print("Network error when fetching Curated Recommendations: \(reason)")

            case .Other(let code?, let reason) where code == 400:
                print("Bad Request: \(reason)")

            case .Other(let code?, let reason) where code == 422:
                print("Validation Error: \(reason)")

            case .Other(let code?, let reason) where (500...599).contains(code):
                print("Server Error: \(reason)")

            case .Other(nil, let reason):
                print("Missing status code: \(reason)")

            case .Other(_, let reason):
                print("Unexpected Error: \(reason)")
            }
            return []
        } catch {
            print("Unhandled error: \(error)")
            return []
        }
    }

    // Returns nil if the locale is not supported
    static func islocaleSupported(_ locale: String) -> Bool {
        return MerinoProvider.SupportedLocales.contains(locale)
    }

    private var shouldUseMockData: Bool {
//        guard let pocketKey = pocketKey else {
//            return featureFlags.isCoreFeatureEnabled(.useMockData) ? true : false
//        }
//
//        return featureFlags.isCoreFeatureEnabled(.useMockData) && pocketKey.isEmpty
        return false
    }

    private func getMockDataFeed(count: Int32 = 2) async throws -> [RecommendationDataItem] {
//        guard let path = Bundle(for: type(of: self)).path(forResource: "pocketglobalfeed", ofType: "json"),
//              let data = try? Data(contentsOf: URL(fileURLWithPath: path))
//        else {
//            throw Error.failure
//        }
//
//        let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any]
//        guard let items = json?["recommendations"] as? [[String: Any]] else {
//            throw Error.failure
//        }
//
//        return Array(PocketFeedStory.parseJSON(list: items).prefix(count))
        return []
    }
}
