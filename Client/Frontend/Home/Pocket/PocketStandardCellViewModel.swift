// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

class PocketStandardCellViewModel {
    var title: String { story.title }
    var imageURL: URL { story.imageURL }
    var url: URL? { story.url }
    var sponsor: String? { story.sponsor }
    var description: String {
        if let sponsor = story.sponsor {
            return sponsor
        } else {
            return "\(story.domain) • \(String.localizedStringWithFormat(String.FirefoxHomepage.Pocket.NumberOfMinutes, story.timeToRead ?? 0))"
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

    private let story: PocketStory

    init(story: PocketStory) {
        self.story = story
    }
}
