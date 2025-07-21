// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import MozillaAppServices

@testable import Client

<<<<<<< HEAD:firefox-ios/firefox-ios-tests/Tests/ClientTests/Mocks/MockPocketAPI.swift
class MockPocketAPI: PocketStoriesProviding {
    init(result: Result<[PocketFeedStory], Error>) {
        self.result = result
    }

    var result: Result<[PocketFeedStory], Error>
=======
final class MockMerinoAPI: MerinoStoriesProviding {
    init(result: Result<[RecommendationDataItem], Error>) {
        self.result = result
    }

    let result: Result<[RecommendationDataItem], Error>
>>>>>>> 72d19c08e (Add FXIOS-12218 [Homepage] Add Merino with AS client (#28099)):firefox-ios/firefox-ios-tests/Tests/ClientTests/Mocks/MockMerinoAPI.swift

    func fetchStories(items: Int32) async throws -> [RecommendationDataItem] {
        switch result {
        case .success(let value):
            return Array(value.prefix(Int(items)))
        case .failure(let error):
            throw error
        }
    }
}
