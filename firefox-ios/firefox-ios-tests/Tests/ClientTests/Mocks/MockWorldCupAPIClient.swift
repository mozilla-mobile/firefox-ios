// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client

import Foundation
import MozillaAppServices

enum MockWorldCupClientError: Error {
    case network
}

final class MockWorldCupAPIClient: WorldCupAPIClientProtocol, @unchecked Sendable {
    private let result: Result<WorldCupMatchesResponse?, Error>
    private(set) var fetchCount = 0
    private(set) var lastQuery: WorldCupQuery?

    init(result: Result<WorldCupMatchesResponse?, Error>) {
        self.result = result
    }

    func fetch(_ query: WorldCupQuery, options: WorldCupOptions) throws -> WorldCupMatchesResponse? {
        fetchCount += 1
        lastQuery = query
        return try result.get()
    }

    /// Not exercised by current callers — strategies call `fetch` directly.
    /// Provided to satisfy the protocol.
    func loadMatches(query: WorldCupQuery) async -> WorldCupMatchesResponse? {
        nil
    }
}
