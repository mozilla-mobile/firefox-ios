// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

class StoryStandardCellViewModel {
    var title: String { story.title }
    var imageURL: URL? { story.imageURL }
    var url: URL? { story.url }
    var description: String {
        return  "\(story.publisher)"
    }
    var accessibilityLabel: String {
        return "\(title), \(description)"
    }

    /// Merino will eventually have sponsors, so there's no reason to change the logic
    /// in the UI for this now.
    var shouldHideSponsor: Bool { return true }

    var onTap: (IndexPath) -> Void = { _ in }

    var tag = 0

    private let story: MerinoStory

    init(story: MerinoStory) {
        self.story = story
    }
}
