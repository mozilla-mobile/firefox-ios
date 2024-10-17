// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

class PocketManager {
    private let pocketAPI: PocketStoriesProviding
    private let storyProvider: StoryProvider

    init(pocketAPI: PocketStoriesProviding) {
        self.pocketAPI = pocketAPI
        self.storyProvider = StoryProvider(pocketAPI: pocketAPI)
    }

    func getPocketItems() async -> [PocketItem] {
        let stories = await storyProvider.fetchPocketStories()
        return stories.compactMap { PocketItem(story: $0) }
    }
}
