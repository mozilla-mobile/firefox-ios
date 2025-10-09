// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import MozillaAppServices

@testable import Client

final class MockStoryProvider: StoryProviderInterface {
    var fetchHomepageStoriesCalled = 0
    var fetchDiscoverMoreStoriesCalled = 0

    func fetchHomepageStories() async -> [MerinoStory] {
        fetchHomepageStoriesCalled += 1

        getMockStoriesData().compactMap { MerinoStory(from: $0) }
    }

    func fetchDiscoverMoreStories() async -> [MerinoStory] {
        fetchDiscoverMoreStoriesCalled += 1

        getMockStoriesData.compactMap { MerinoStory(from: $0) }
    }

    private func getMockStoriesData() -> [RecommendationDataItem] {
        return [
            .makeItem("feed1"),
            .makeItem("feed2"),
            .makeItem("feed3"),
        ]
    }
}
