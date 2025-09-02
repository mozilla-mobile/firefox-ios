// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/
import Common
import Shared

enum TrendingSearchClientError: Error {
    case invalidHTTPResponse
    case unableToRetrieveResponse
}

final class TrendingSearchClient {
    private let searchEngine: OpenSearchEngine
    private let logger: Logger
    
    init(searchEngine: OpenSearchEngine,
         logger: Logger = DefaultLogger.shared) {
        self.searchEngine = searchEngine
        self.logger = logger
    }
    
    private var urlSession = makeURLSession(
        userAgent: UserAgent.mobileUserAgent(),
        configuration: URLSessionConfiguration.defaultMPTCP
    )
    
    func getTrendingSarches() async throws -> [String] {
        do {
            guard let url = searchEngine.trendingURLForQuery() else { return [] }
            let (data, response) = try await urlSession.data(from: url)
            guard let response = validatedHTTPResponse(response, statusCode: 200..<300) else {
                self.logger.log("Response isn't valid based on status codes.",
                                level: .debug,
                                category: .legacyHomepage)
                throw TrendingSearchClientError.invalidHTTPResponse
            }
            let json = try? JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed)
            return json as? [String] ?? []
        } catch {
            throw TrendingSearchClientError.unableToRetrieveResponse
        }
    }
}
