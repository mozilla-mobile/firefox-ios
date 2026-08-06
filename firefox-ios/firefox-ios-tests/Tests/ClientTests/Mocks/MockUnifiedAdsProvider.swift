// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client

final class MockUnifiedAdsProvider: UnifiedAdsProviderInterface, @unchecked Sendable {
    private var result: SponsoredTileResult?

    init(result: SponsoredTileResult?) {
        self.result = result
    }

    func fetchTiles(completion: @escaping @Sendable (SponsoredTileResult) -> Void) {
        guard let result else { return }

        switch result {
        case .success(let sponsoredSites):
            completion(.success(sponsoredSites))
        case .failure(let error):
            completion(.failure(error))
        }
    }
}
