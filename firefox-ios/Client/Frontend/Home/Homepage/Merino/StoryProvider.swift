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

final class StoryProvider: StoryProviderInterface, FeatureFlaggable, Sendable {
    private struct Constants {
        static let defaultNumberOfHomepageStories = 100
    }

    private let merinoAPI: MerinoStoriesProviding

    init(merinoAPI: MerinoStoriesProviding) {
        self.merinoAPI = merinoAPI
    }

    func fetchHomepageStories() async -> MerinoStoryResponse {
        return await fetchStories(Constants.defaultNumberOfHomepageStories)
    }

    func prefetchStories() async {
        // Because a prefetch basically warms the cache, we don't actually need
        // to do anything with the results
        _ = try? await merinoAPI.fetchStories(Constants.defaultNumberOfHomepageStories)
    }

    private func fetchStories(_ numberOfRequestedStories: Int) async -> MerinoStoryResponse {
        let data = (try? await merinoAPI.fetchStories(numberOfRequestedStories)) ?? []
        return MerinoStoryResponse(
            stories: data
                .map(MerinoStory.init)
                .compactMap { MerinoStoryConfiguration(story: $0) }
        )
    }
}
