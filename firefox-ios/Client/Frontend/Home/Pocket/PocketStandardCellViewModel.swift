// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

class PocketStandardCellViewModel {
    var title: String { story.title }
    var imageURL: URL { story.imageURL }
    var url: URL? { story.url }
//    var sponsor: String? { story.sponsor }
    var description: String {
        return  "\(story.publisher)"
    }
    var accessibilityLabel: String {
        return "\(title), \(description)"
    }

    var shouldHideSponsor: Bool {
        // RGB
        return true
//        return sponsor == nil
    }

    var onTap: (IndexPath) -> Void = { _ in }

    var tag = 0

    private let story: MerinoStory

    init(story: MerinoStory) {
        self.story = story
    }
}
