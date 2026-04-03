// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import MozillaAppServices

@testable import Client

final class MerinoCategoryTests: XCTestCase {
    func test_init_mapsAllFieldsFromFeedSection() {
        let items: [RecommendationDataItem] = [.makeItem("rec1"), .makeItem("rec2")]
        let section = FeedSection.makeSection(
            feedId: "travel",
            receivedFeedRank: 3,
            recommendations: items,
            title: "Travel",
            subtitle: "Explore the world",
            isFollowed: true,
            isBlocked: false
        )

        let category = MerinoCategory(from: section)

        XCTAssertEqual(category.feedID, "travel")
        XCTAssertEqual(category.title, "Travel")
        XCTAssertEqual(category.subtitle, "Explore the world")
        XCTAssertEqual(category.receivedFeedRank, 3)
        XCTAssertTrue(category.isFollowed)
        XCTAssertFalse(category.isBlocked)
    }

    func test_init_transformsRecommendations() {
        let items: [RecommendationDataItem] = [.makeItem("rec1"), .makeItem("rec2")]
        let section = FeedSection.makeSection(recommendations: items)

        let category = MerinoCategory(from: section)

        XCTAssertEqual(category.recommendations.count, 2)
        XCTAssertEqual(category.recommendations.first?.title, "rec1")
        XCTAssertEqual(category.recommendations.last?.title, "rec2")
    }

    func test_init_handlesNilSubtitle() {
        let section = FeedSection.makeSection(subtitle: nil)

        let category = MerinoCategory(from: section)

        XCTAssertNil(category.subtitle)
    }

    func test_init_handlesEmptyRecommendations() {
        let section = FeedSection.makeSection(recommendations: [])

        let category = MerinoCategory(from: section)

        XCTAssertTrue(category.recommendations.isEmpty)
    }
}
