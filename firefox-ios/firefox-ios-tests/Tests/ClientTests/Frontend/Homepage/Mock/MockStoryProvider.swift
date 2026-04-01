// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import MozillaAppServices

@testable import Client

final class MockStoryProvider: StoryProviderInterface, @unchecked Sendable {
    var fetchHomepageStoriesCalled = 0
    var prefetchStoriesCalled = 0

    func fetchHomepageStories() async -> MerinoStoryResponse {
        fetchHomepageStoriesCalled += 1

        return MerinoStoryResponse(
            stories: getMockStoriesData()
                .map({ MerinoStory(from: $0) })
                .compactMap({ MerinoStoryConfiguration(story: $0) })
        )
    }

    func prefetchStories() async {
        prefetchStoriesCalled += 1
    }

    private func getMockStoriesData() -> [RecommendationDataItem] {
        return [
            .makeItem("feed1"),
            .makeItem("feed2"),
            .makeItem("feed3"),
        ]
    }
}
