// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import MozillaAppServices

struct MerinoCategory: Equatable, Hashable {
    let feedID: String
    let recommendations: [MerinoStoryConfiguration]
    let isBlocked: Bool
    let isFollowed: Bool
    let title: String
    let subtitle: String?
    let receivedFeedRank: Int

    init(from item: FeedSection) {
        self.init(
            feedID: item.feedId,
            recommendations: item.recommendations
                .map({ MerinoStory(from: $0) })
                .map({ MerinoStoryConfiguration(story: $0) }),
            isBlocked: item.isBlocked,
            isFollowed: item.isFollowed,
            title: item.title,
            subtitle: item.subtitle,
            receivedFeedRank: Int(item.receivedFeedRank),
        )
    }

    init(
        feedID: String,
        recommendations: [MerinoStoryConfiguration],
        isBlocked: Bool,
        isFollowed: Bool,
        title: String,
        subtitle: String?,
        receivedFeedRank: Int
    ) {
        self.feedID = feedID
        self.recommendations = recommendations
        self.isBlocked = isBlocked
        self.isFollowed = isFollowed
        self.title = title
        self.subtitle = subtitle
        self.receivedFeedRank = receivedFeedRank
    }
}
