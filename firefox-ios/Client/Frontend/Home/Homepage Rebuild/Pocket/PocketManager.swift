// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

protocol PocketManagerProvider {
    func getPocketItems() async -> [PocketStoryConfiguration]
}

final class PocketManager: PocketManagerProvider {
    private let storyProvider: StoryProvider

    init(pocketAPI: PocketStoriesProviding) {
        self.storyProvider = StoryProvider(pocketAPI: pocketAPI)
    }

    func getPocketItems() async -> [PocketStoryConfiguration] {
        let stories = await storyProvider.fetchPocketStories()
        return stories.compactMap { PocketStoryConfiguration(story: $0) }
    }
}
