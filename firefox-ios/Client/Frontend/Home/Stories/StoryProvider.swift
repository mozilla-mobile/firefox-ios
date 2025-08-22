// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import MozillaAppServices
import Shared

final class StoryProvider: FeatureFlaggable, Sendable {
    private let numberOfStories: Int
    private let merinoAPI: MerinoStoriesProviding

    init(
        merinoAPI: MerinoStoriesProviding,
        numberOfStories: Int = 12
    ) {
        self.merinoAPI = merinoAPI
        self.numberOfStories = numberOfStories
    }

    func fetchStories() async -> [MerinoStory] {
        let isStoriesRedesignEnabled = featureFlags.isFeatureEnabled(.homepageStoriesRedesign, checking: .buildOnly)
        let numberOfStoriesIfRedesignEnabled = 9
        let numberOfStories = isStoriesRedesignEnabled
            ? numberOfStoriesIfRedesignEnabled
            : self.numberOfStories
        let data = (try? await merinoAPI.fetchStories(numberOfStories)) ?? []
        return data.map(MerinoStory.init)
    }
}
