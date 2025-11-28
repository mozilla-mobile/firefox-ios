// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
@testable import Client

final class MockTrendingSearchClient: TrendingSearchClientProvider, @unchecked Sendable {
    let result: Result<[String], Error>
    var getTrendingSearchesCalledCount = 0
    init(result: Result<[String], Error> = .success([])) {
        self.result = result
    }
    func getTrendingSearches(for searchEngine: TrendingSearchEngine?) async throws -> [String] {
        getTrendingSearchesCalledCount += 1
        return try result.get()
    }
}
