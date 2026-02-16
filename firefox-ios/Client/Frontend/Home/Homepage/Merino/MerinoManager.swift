// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

protocol MerinoManagerProvider: Sendable {
    func getMerinoItems(source: StorySource) async -> [MerinoStoryConfiguration]
    func prefetchStories() async
}

final class MerinoManager: MerinoManagerProvider {
    private let storyProvider: StoryProviderInterface

    init(storyProvider: StoryProviderInterface) {
        self.storyProvider = storyProvider
    }

    func getMerinoItems(source: StorySource) async -> [MerinoStoryConfiguration] {
        let stories: [MerinoStory]
        switch source {
        case .homepage:
            stories = await storyProvider.fetchHomepageStories()
        case .storiesFeed:
            stories = await storyProvider.fetchDiscoverMoreStories()
        }
        return stories.compactMap { MerinoStoryConfiguration(story: $0) }
    }

    func prefetchStories() async {
        await storyProvider.prefetchStories()
    }
}

enum StorySource {
    case homepage
    case storiesFeed
}
