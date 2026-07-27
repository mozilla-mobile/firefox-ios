// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client

import Shared

final class MockUnifiedAdsProvider: UnifiedAdsProviderInterface, @unchecked Sendable {
    private let result: UnifiedTileResult?

    init(result: UnifiedTileResult?) {
        self.result = result
    }

    func fetchTiles(timestamp: Timestamp) async -> UnifiedTileResult {
        guard let result else {
            // Simulates a provider that never returns, so the caller must rely on its own timeout.
            try? await Task.sleep(nanoseconds: .max)
            return .success([])
        }
        return result
    }
}
