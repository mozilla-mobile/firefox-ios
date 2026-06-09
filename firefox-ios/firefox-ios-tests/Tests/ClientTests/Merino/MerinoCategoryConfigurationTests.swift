// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import MozillaAppServices

@testable import Client

final class MerinoCategoryConfigurationTests: XCTestCase {
    func test_exposesAllProperties() {
        let items: [RecommendationDataItem] = [.makeItem("rec1")]
        let category = MerinoCategory(
            feedID: "arts",
            recommendations: items.map({ MerinoStoryConfiguration(story: MerinoStory(from: $0)) }),
            isBlocked: true,
            isFollowed: false,
            title: "Arts",
            subtitle: "Culture and more",
            receivedFeedRank: 5
        )

        let config = MerinoCategoryConfiguration(category: category)

        XCTAssertEqual(config.feedID, "arts")
        XCTAssertEqual(config.title, "Arts")
        XCTAssertEqual(config.subtitle, "Culture and more")
        XCTAssertEqual(config.rank, 5)
        XCTAssertTrue(config.isBlocked)
        XCTAssertFalse(config.isFollowed)
        XCTAssertEqual(config.recommendations.count, 1)
        XCTAssertEqual(config.recommendations.first?.title, "rec1")
    }

    func test_equalConfigs_areEqual() {
        let category = MerinoCategory(
            feedID: "travel",
            recommendations: [],
            isBlocked: false,
            isFollowed: true,
            title: "Travel",
            subtitle: nil,
            receivedFeedRank: 1
        )

        let config1 = MerinoCategoryConfiguration(category: category)
        let config2 = MerinoCategoryConfiguration(category: category)

        XCTAssertEqual(config1, config2)
    }

    func test_differentConfigs_areNotEqual() {
        let category1 = MerinoCategory(
            feedID: "travel",
            recommendations: [],
            isBlocked: false,
            isFollowed: true,
            title: "Travel",
            subtitle: nil,
            receivedFeedRank: 1
        )
        let category2 = MerinoCategory(
            feedID: "arts",
            recommendations: [],
            isBlocked: false,
            isFollowed: false,
            title: "Arts",
            subtitle: nil,
            receivedFeedRank: 2
        )

        let config1 = MerinoCategoryConfiguration(category: category1)
        let config2 = MerinoCategoryConfiguration(category: category2)

        XCTAssertNotEqual(config1, config2)
    }

    func test_equalConfigs_haveSameHash() {
        let category = MerinoCategory(
            feedID: "travel",
            recommendations: [],
            isBlocked: false,
            isFollowed: true,
            title: "Travel",
            subtitle: nil,
            receivedFeedRank: 1
        )

        let config1 = MerinoCategoryConfiguration(category: category)
        let config2 = MerinoCategoryConfiguration(category: category)

        XCTAssertEqual(config1.hashValue, config2.hashValue)
    }
}
