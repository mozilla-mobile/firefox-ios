// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import MozillaAppServices

@testable import Client

final class MockMerinoAPI: MerinoStoriesProviding {
    init(result: Result<[RecommendationDataItem], Error>) {
        self.result = result
    }

    let result: Result<[RecommendationDataItem], Error>

    func fetchStories(_ itemCount: Int) async throws -> [RecommendationDataItem] {
        switch result {
        case .success(let value):
            return Array(value.prefix(itemCount))
        case .failure(let error):
            throw error
        }
    }
}
