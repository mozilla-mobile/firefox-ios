// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

class PocketManager {
    private let pocketAPI: PocketStoriesProviding
    private let storyProvider: StoryProvider
    private var pocketItems: [PocketItem]?

    init(profile: Profile) {
        self.pocketAPI = PocketProvider(prefs: profile.prefs)
        self.storyProvider = StoryProvider(pocketAPI: pocketAPI)
    }

    func getPocketItems() async -> [PocketItem] {
        let stories = await storyProvider.fetchPocketStories()
        return stories.compactMap { PocketItem(story: $0) }
    }
}

class PocketItem: Equatable, Hashable {
    static func == (lhs: PocketItem, rhs: PocketItem) -> Bool {
        lhs.story == rhs.story
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(self.story)
    }

    private let story: PocketStory

    init(story: PocketStory) {
        self.story = story
    }

    var title: String { story.title }
    var imageURL: URL { story.imageURL }
    var url: URL? { story.url }
    var sponsor: String? { story.sponsor }
    var description: String {
        if let sponsor = story.sponsor {
            return sponsor
        } else {
            if let timeToRead = story.timeToRead {
                return "\(story.domain) • \(String.localizedStringWithFormat(String.FirefoxHomepage.Pocket.NumberOfMinutes, timeToRead))"
            } else {
               return  "\(story.domain)"
            }
        }
    }
    var accessibilityLabel: String {
        return "\(title), \(description)"
    }

    var shouldHideSponsor: Bool {
        return sponsor == nil
    }

    var onTap: (IndexPath) -> Void = { _ in }

    var tag: Int = 0
}
