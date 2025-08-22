// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

protocol MerinoManagerProvider: Sendable {
    func getMerinoItems() async -> [MerinoStoryConfiguration]
}

final class MerinoManager: MerinoManagerProvider {
    private let storyProvider: StoryProvider

    init(merinoAPI: MerinoStoriesProviding) {
        self.storyProvider = StoryProvider(merinoAPI: merinoAPI)
    }

    func getMerinoItems() async -> [MerinoStoryConfiguration] {
        let stories = await storyProvider.fetchHomepageStories()
        return stories.compactMap { MerinoStoryConfiguration(story: $0) }
    }
}
