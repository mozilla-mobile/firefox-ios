// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Client

final class TrackingProtectionPageStatsTests: XCTestCase {
    func testAdding_firstHostForCategory_reportsInserted() {
        let stats = TPPageStats()

        let result = stats.adding(matchingBlocklist: .advertising, host: "tracker.example")

        XCTAssertTrue(result.inserted)
        XCTAssertEqual(result.stats.getTrackersBlockedForCategory(.advertising), 1)
        XCTAssertEqual(result.stats.total, 1)
    }

    func testAdding_duplicateHostInSameCategory_reportsNotInserted() {
        let stats = TPPageStats()
            .adding(matchingBlocklist: .advertising, host: "tracker.example").stats

        let result = stats.adding(matchingBlocklist: .advertising, host: "tracker.example")

        XCTAssertFalse(result.inserted, "A host already counted for the category is not re-inserted")
        XCTAssertEqual(result.stats.getTrackersBlockedForCategory(.advertising), 1)
        XCTAssertEqual(result.stats.total, 1)
    }

    func testAdding_sameHostDifferentCategories_reportsInsertedForEach() {
        let first = TPPageStats().adding(matchingBlocklist: .advertising, host: "tracker.example")
        let second = first.stats.adding(matchingBlocklist: .analytics, host: "tracker.example")

        XCTAssertTrue(first.inserted)
        XCTAssertTrue(second.inserted)
        XCTAssertEqual(second.stats.getTrackersBlockedForCategory(.advertising), 1)
        XCTAssertEqual(second.stats.getTrackersBlockedForCategory(.analytics), 1)
        XCTAssertEqual(second.stats.total, 2)
    }

    func testAdding_distinctHostsSameCategory_eachInserted() {
        let first = TPPageStats().adding(matchingBlocklist: .social, host: "a.example")
        let second = first.stats.adding(matchingBlocklist: .social, host: "b.example")

        XCTAssertTrue(first.inserted)
        XCTAssertTrue(second.inserted)
        XCTAssertEqual(second.stats.getTrackersBlockedForCategory(.social), 2)
    }

    func testCreate_matchesAddingStats() {
        let created = TPPageStats().create(matchingBlocklist: .fingerprinting, host: "fp.example")

        XCTAssertEqual(created.getTrackersBlockedForCategory(.fingerprinting), 1)
        XCTAssertEqual(created.total, 1)
    }
}
