// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import MozillaAppServices

protocol MerinoFeedFetching: Sendable {
    func fetch(
        itemCount: Int,
        locale: CuratedRecommendationLocale,
        userAgent: String
    ) async -> [RecommendationDataItem]
}

struct MerinoFeedFetcher: MerinoFeedFetching {
    let baseURL: String
    let logger: Logger

    func fetch(
        itemCount: Int,
        locale: CuratedRecommendationLocale,
        userAgent: String
    ) async -> [RecommendationDataItem] {
        do {
            let client = try CuratedRecommendationsClient(
                config: CuratedRecommendationsConfig(
                    baseHost: baseURL,
                    userAgentHeader: userAgent
                )
            )
            let request = CuratedRecommendationsRequest(locale: locale, count: Int32(itemCount))
            let response = try client.getCuratedRecommendations(request: request)
            return response.data
        } catch let error as CuratedRecommendationsApiError {
            switch error {
            case .Network(let reason):
                logger.log(
                    "Network error when fetching Curated Recommendations: \(reason)",
                    level: .debug,
                    category: .merino
                )
            case .Other(let code?, let reason) where code == 400:
                logger.log(
                    "Bad Request: \(reason)",
                    level: .debug,
                    category: .merino
                )
            case .Other(let code?, let reason) where code == 422:
                logger.log(
                    "Validation Error: \(reason)",
                    level: .debug,
                    category: .merino
                )
            case .Other(let code?, let reason) where (500...599).contains(code):
                logger.log(
                    "Server Error: \(reason)",
                    level: .debug,
                    category: .merino
                )
            case .Other(nil, let reason):
                logger.log(
                    "Missing status code: \(reason)",
                    level: .debug,
                    category: .merino
                )
            case .Other(_, let reason):
                logger.log(
                    "Unexpected Error: \(reason)",
                    level: .debug,
                    category: .merino
                )
            }
            return []
        } catch {
            logger.log(
                "Unhandled error: \(error)",
                level: .debug,
                category: .merino
            )
            return []
        }
    }
}
