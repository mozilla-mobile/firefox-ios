// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import MozillaAppServices
import Shared

protocol StoryProviderInterface: Sendable {
    func fetchHomepageStories() async -> [MerinoStory]
    func fetchDiscoverMoreStories() async -> [MerinoStory]
}

final class StoryProvider: StoryProviderInterface, FeatureFlaggable, Sendable {
    private struct Constants {
        static let defaultNumberOfHomepageStories = 12
        static let defaultNumberOfDiscoverMoreStories = 20
    }

    private let merinoAPI: MerinoStoriesProviding

    init(merinoAPI: MerinoStoriesProviding) {
        self.merinoAPI = merinoAPI
    }

    func fetchHomepageStories() async -> [MerinoStory] {
        let numberOfStoriesIfRedesignEnabled = 9
        let numberOfStories = isAnyStoriesRedesignEnabled
            ? numberOfStoriesIfRedesignEnabled
            : Constants.defaultNumberOfHomepageStories
        return await fetchStories(numberOfStories)
    }

    func fetchDiscoverMoreStories() async -> [MerinoStory] {
        return await fetchStories(Constants.defaultNumberOfDiscoverMoreStories).shuffled()
    }

    private func fetchStories(_ numberOfRequestedStories: Int) async -> [MerinoStory] {
        let data = (try? await merinoAPI.fetchStories(numberOfRequestedStories)) ?? []
        return data.map(MerinoStory.init)
    }
}
