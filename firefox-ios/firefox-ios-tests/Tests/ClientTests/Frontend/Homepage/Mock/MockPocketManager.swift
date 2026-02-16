// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import MozillaAppServices

@testable import Client

final class MockMerinoManager: MerinoManagerProvider, @unchecked Sendable {
    var getMerinoItemsCalled = 0
    var prefetchStoriesCalled = 0

    func getMerinoItems(source: StorySource) async -> [MerinoStoryConfiguration] {
        getMerinoItemsCalled += 1
        let stories: [RecommendationDataItem] = [
            .makeItem("feed1"),
            .makeItem("feed2"),
            .makeItem("feed3"),
        ]

        return stories.compactMap { MerinoStoryConfiguration(story: MerinoStory(from: $0)) }
    }

    func prefetchStories() async {
        prefetchStoriesCalled += 1
    }
}
