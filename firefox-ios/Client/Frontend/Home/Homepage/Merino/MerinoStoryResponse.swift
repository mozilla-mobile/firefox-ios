// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Converts the Merino story model to be presentable for the `StoryCell` view
final class MerinoStoryResponse: Sendable, Equatable, Hashable {
    let stories: [MerinoStoryConfiguration]?
    let categories: [MerinoCategoryConfiguration]?

    init(
        stories: [MerinoStoryConfiguration]? = nil,
        categories: [MerinoCategoryConfiguration]? = nil
    ) {
        self.stories = stories?.sorted { $0.rank < $1.rank }
        self.categories = categories?
            .map(Self.categoryWithSortedRecommendations)
            .sorted { $0.rank < $1.rank }
    }

    private static func categoryWithSortedRecommendations(
        _ category: MerinoCategoryConfiguration
    ) -> MerinoCategoryConfiguration {
        return MerinoCategoryConfiguration(
            category: MerinoCategory(
                feedID: category.feedID,
                recommendations: category.recommendations.sorted { $0.rank < $1.rank },
                isBlocked: category.isBlocked,
                isFollowed: category.isFollowed,
                title: category.title,
                subtitle: category.subtitle,
                receivedFeedRank: category.rank
            )
        )
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
