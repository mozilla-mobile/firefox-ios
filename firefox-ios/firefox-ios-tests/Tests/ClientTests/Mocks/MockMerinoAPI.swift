// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import MozillaAppServices

@testable import Client

final class MockMerinoAPI: MerinoStoriesProviding {
    init(result: Result<CuratedRecommendationsResponse, Error>) {
        self.result = result
    }

    let result: Result<CuratedRecommendationsResponse, Error>

    func fetchContent() async throws -> CuratedRecommendationsResponse {
        switch result {
        case .success(let value):
            return value
        case .failure(let error):
            throw error
        }
    }
}
