// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Default fetch strategy. A single attempt with no retry. Returns `nil` on
/// any failure (FFI error, decode error, missing payload).
struct WorldCupNormalFetchStrategy: WorldCupFetchStrategyProtocol {
    func loadMatches(using client: WorldCupAPIClientProtocol,
                     query: WorldCupQuery) async -> WorldCupMatchesResponse? {
        await Task.detached(priority: .userInitiated) { () -> WorldCupMatchesResponse? in
            try? client.fetch(query, options: WorldCupAPIClient.emptyOptions)
        }.value
    }
}
