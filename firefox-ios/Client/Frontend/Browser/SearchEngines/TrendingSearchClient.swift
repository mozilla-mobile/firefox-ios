// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Shared

/// A protocol that defines a provider for fetching trending searches.
/// Conforming types are responsible for supplying the URL endpoint
/// used to fetch trending searches from a specific search engine.
public protocol TrendingSearchEngine: Sendable {
    func trendingURLForEngine() -> URL?
}

/// Abstraction for any search client that can return trending searches. Able to mock for testing.
public protocol TrendingSearchClientProvider: Sendable {
    func getTrendingSearches() async throws -> [String]
}

enum TrendingSearchClientError: Error {
    case invalidHTTPResponse
    case unableToParseJsonData
}

/// A service responsible for retrieving trending searches from a given search engine.
///
/// This class uses a `TrendingSearchEngine` to provide the URL of the trending
/// searches endpoint, fetches the data over the network, and parses it into
/// a list of searches.
final class TrendingSearchClient: TrendingSearchClientProvider, Sendable {
    private let searchEngine: TrendingSearchEngine?
    private let logger: Logger
    private let urlSession: URLSession

    init(searchEngine: TrendingSearchEngine?,
         logger: Logger = DefaultLogger.shared,
         session: URLSession = makeURLSession(
            userAgent: UserAgent.mobileUserAgent(),
            configuration: URLSessionConfiguration.ephemeralMPTCP
         )
    ) {
        self.searchEngine = searchEngine
        self.logger = logger
        self.urlSession = session
    }

    func getTrendingSearches() async throws -> [String] {
        do {
            guard let searchEngine, let url = searchEngine.trendingURLForEngine() else { return [] }
            let data = try await fetch(from: url)

            // Due to how the response data is formatted, we use index of 1 to parse the list of searches from response data.
            // Can test what the response is using `https://www.bing.com/osjson.aspx.`
            guard let json = try? JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed) as? [Any],
                  let suggestions = json[safe: 1] as? [String]
            else {
                logger.log("Response was not able to be parsed appropriately.",
                           level: .debug,
                           category: .searchEngines)
                throw TrendingSearchClientError.unableToParseJsonData
            }

            return suggestions
        } catch {
            throw error
        }
    }

    private func fetch(from url: URL) async throws -> Data {
        let (data, response) = try await urlSession.data(from: url)
        let isValidResponse = validatedHTTPResponse(response, statusCode: 200..<300)

        guard isValidResponse != nil else {
            logger.log("Response isn't valid based on status codes.",
                       level: .debug,
                       category: .searchEngines)
            throw TrendingSearchClientError.invalidHTTPResponse
        }
        return data
    }
}
