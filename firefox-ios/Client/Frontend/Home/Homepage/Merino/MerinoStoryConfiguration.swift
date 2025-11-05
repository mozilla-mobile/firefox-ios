// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Converts the Merino story model to be presentable for the `MerinoStandardCell` view
final class MerinoStoryConfiguration: Sendable, Equatable, Hashable {
    private let story: MerinoStory

    init(story: MerinoStory) {
        self.story = story
    }

    var title: String { story.title }
    var url: URL? { story.url }
    var imageURL: URL? { story.imageURL }
    var iconURL: URL? { story.iconURL }
    var description: String {
        return "\(story.publisher)"
    }
    var accessibilityLabel: String {
        return "\(title), \(description)"
    }

    var shouldHideSponsor: Bool {
        // Merino will add sponsor's in the future
        return true
    }

    // MARK: - Equatable
    static func == (lhs: MerinoStoryConfiguration, rhs: MerinoStoryConfiguration) -> Bool {
        lhs.story == rhs.story
    }

    // MARK: - Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.story)
    }
}
