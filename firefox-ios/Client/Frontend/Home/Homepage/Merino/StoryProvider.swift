// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import MozillaAppServices
import Shared

protocol StoryProviderInterface: Sendable {
    func fetchHomepageStories() async -> MerinoStoryResponse
    func prefetchStories() async
}

final class StoryProvider: StoryProviderInterface, Sendable {
    private let merinoAPI: MerinoStoriesProviding

    init(merinoAPI: MerinoStoriesProviding) {
        self.merinoAPI = merinoAPI
    }

    func fetchHomepageStories() async -> MerinoStoryResponse {
        guard let response = try? await merinoAPI.fetchContent() else {
            return MerinoStoryResponse(stories: [])
        }

        return MerinoStoryResponse(
            stories: response.data
                .map(MerinoStory.init)
                .compactMap { MerinoStoryConfiguration(story: $0) },
            categories: response.feeds?
                .compactMap({ MerinoCategory(from: $0) })
                .compactMap { MerinoCategoryConfiguration(category: $0) }
        )
    }

    func prefetchStories() async {
        // Because a prefetch basically warms the cache, we don't actually need
        // to do anything with the results
        _ = try? await merinoAPI.fetchContent()
    }
}
