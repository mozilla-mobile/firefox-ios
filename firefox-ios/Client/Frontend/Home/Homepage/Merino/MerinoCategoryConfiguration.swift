// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

final class MerinoCategoryConfiguration: Sendable, Equatable, Hashable {
    private let category: MerinoCategory

    init(category: MerinoCategory) {
        self.category = category
    }

    var feedID: String { category.feedID }
    var title: String { category.title }
    var subtitle: String? { category.subtitle }
    var recommendations: [MerinoStoryConfiguration] { category.recommendations }
    var rank: Int { category.receivedFeedRank }
    var isBlocked: Bool { category.isBlocked }
    var isFollowed: Bool { category.isFollowed }

    // MARK: - Equatable
    static func == (
        lhs: MerinoCategoryConfiguration,
        rhs: MerinoCategoryConfiguration
    ) -> Bool {
        lhs.category == rhs.category
    }

    // MARK: - Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.category)
    }
}
