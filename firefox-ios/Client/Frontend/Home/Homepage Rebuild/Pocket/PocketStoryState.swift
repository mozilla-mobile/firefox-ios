// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Converts the pocket story model to be presentable for the `PocketStandardCell` view
class PocketStoryState: Equatable, Hashable {
    private let story: PocketStory

    init(story: PocketStory) {
        self.story = story
    }

    var title: String { story.title }
    var imageURL: URL { story.imageURL }
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
        return story.sponsor == nil
    }

    // MARK: - Equatable
    static func == (lhs: PocketStoryState, rhs: PocketStoryState) -> Bool {
        lhs.story == rhs.story
    }

    // MARK: - Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.story)
    }
}
