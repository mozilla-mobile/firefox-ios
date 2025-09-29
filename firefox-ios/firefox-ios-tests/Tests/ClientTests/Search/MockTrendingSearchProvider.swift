// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
@testable import Client

final class MockTrendingSearchClient: TrendingSearchClientProvider, Sendable {
    let result: Result<[String], Error>
    init(result: Result<[String], Error> = .success([])) {
        self.result = result
    }
    func getTrendingSearches() async throws -> [String] {
        try result.get()
    }
}
