// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client

import Shared

final class MockUnifiedAdsProvider: UnifiedAdsProviderInterface, @unchecked Sendable {
    private var result: UnifiedTileResult

    init(result: UnifiedTileResult) {
        self.result = result
    }

    func fetchTiles(timestamp: Timestamp, completion: @escaping (UnifiedTileResult) -> Void) {
        switch result {
        case .success(let unifiedTiles):
            completion(.success(unifiedTiles))
        case .failure(let error):
            completion(.failure(error))
        }
    }
}
