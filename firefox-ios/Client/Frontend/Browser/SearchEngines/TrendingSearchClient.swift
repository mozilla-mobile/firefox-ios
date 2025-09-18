// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Shared

/// A protocol that defines a provider for fetching trending searches.
/// Conforming types are responsible for supplying the URL endpoint
/// used to fetch trending searches from a specific search engine.
public protocol TrendingSearchEngine {
    func trendingURLForEngine() -> URL?
}

enum TrendingSearchClientError: Error {
    case invalidHTTPResponse
    case invalidParsingJsonData
}

/// A service responsible for retrieving trending searches from a given search engine.
///
/// This class uses a `TrendingSearchEngine` to provide the URL of the trending
/// searches endpoint, fetches the data over the network, and parses it into
/// a list of searches.
final class TrendingSearchClient {
    private let searchEngine: TrendingSearchEngine
    private let logger: Logger
    private var urlSession: URLSession

    init(searchEngine: TrendingSearchEngine,
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

    /// Retrieves the list of trending searches.
    ///
    /// - Returns: An array of trending search strings.
    /// - Throws: `TrendingSearchClientError` if the response is invalid, cannot be retrieved,
    ///           or JSON parsing fails.
    func getTrendingSearches() async throws -> [String] {
        do {
            guard let url = searchEngine.trendingURLForEngine() else { return [] }
            let data = try await fetch(from: url)
            guard let json = try? JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed) as? [Any],
                  let suggestions = json[1] as? [String]
            else {
                self.logger.log("Response was not able to be parsed appropriately.",
                                level: .debug,
                                category: .searchEngines)
                throw TrendingSearchClientError.invalidParsingJsonData
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
            self.logger.log("Response isn't valid based on status codes.",
                            level: .debug,
                            category: .searchEngines)
            throw TrendingSearchClientError.invalidHTTPResponse
        }
        return data
    }
}
