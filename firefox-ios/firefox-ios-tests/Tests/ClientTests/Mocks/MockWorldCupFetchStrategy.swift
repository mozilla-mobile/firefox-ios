// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client

import Foundation

final class MockWorldCupFetchStrategy: WorldCupFetchStrategyProtocol, @unchecked Sendable {
    private let result: WorldCupMatchesResponse?
    private(set) var callCount = 0
    private(set) var lastQuery: WorldCupQuery?

    init(result: WorldCupMatchesResponse? = nil) {
        self.result = result
    }

    func loadMatches(using client: WorldCupAPIClientProtocol,
                     query: WorldCupQuery) async -> WorldCupMatchesResponse? {
        callCount += 1
        lastQuery = query
        return result
    }
}
