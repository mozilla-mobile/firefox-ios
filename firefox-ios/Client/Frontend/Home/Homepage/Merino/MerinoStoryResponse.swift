// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Converts the Merino story model to be presentable for the `StoryCellLarge` view
final class MerinoStoryResponse: Sendable, Equatable, Hashable {
    let stories: [MerinoStoryConfiguration]?
    let categories: [MerinoCategoryConfiguration]?

    init(
        stories: [MerinoStoryConfiguration]? = nil,
        categories: [MerinoCategoryConfiguration]? = nil
    ) {
        self.stories = stories
        self.categories = categories
    }

    // MARK: - Equatable
    static func == (lhs: MerinoStoryResponse, rhs: MerinoStoryResponse) -> Bool {
        lhs.stories == rhs.stories
        && lhs.categories == rhs.categories
    }

    // MARK: - Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(stories)
        hasher.combine(categories)
    }
}
