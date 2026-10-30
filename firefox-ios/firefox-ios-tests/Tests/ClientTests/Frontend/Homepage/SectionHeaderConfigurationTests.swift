// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@testable import Client

final class SectionHeaderConfigurationTests: XCTestCase {
    func test_bookmarks_hasExpectedConfiguration() {
        XCTAssertFalse(SectionHeaderConfiguration.bookmarks.isButtonHidden)
        XCTAssertEqual(SectionHeaderConfiguration.bookmarks.style, .sectionTitle)
    }

    func test_jumpBackIn_hasExpectedConfiguration() {
        XCTAssertFalse(SectionHeaderConfiguration.jumpBackIn.isButtonHidden)
        XCTAssertEqual(SectionHeaderConfiguration.jumpBackIn.style, .sectionTitle)
    }

    func test_topSites_hasExpectedConfiguration() {
        XCTAssertFalse(SectionHeaderConfiguration.topSites.isButtonHidden)
        XCTAssertEqual(SectionHeaderConfiguration.topSites.style, .sectionTitle)
    }

    func test_merino_hasExpectedConfiguration() {
        XCTAssertTrue(SectionHeaderConfiguration.merino.isButtonHidden)
        XCTAssertEqual(SectionHeaderConfiguration.merino.style, .newsAffordance)
    }
}
