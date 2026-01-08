// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Client
import Shared

final class TermsOfUseLinkTypeTests: XCTestCase {
    func testAllCases_ContainsAllLinkTypes() {
        let allCases = TermsOfUseLinkType.allCases
        XCTAssertEqual(allCases.count, 4)
        XCTAssertTrue(allCases.contains(.termsOfUse))
        XCTAssertTrue(allCases.contains(.privacyNotice))
        XCTAssertTrue(allCases.contains(.learnMore))
        XCTAssertTrue(allCases.contains(.here))
    }

    func testURLs_AreNotNil() {
        XCTAssertNotNil(TermsOfUseLinkType.termsOfUse.url)
        XCTAssertNotNil(TermsOfUseLinkType.privacyNotice.url)
        XCTAssertNotNil(TermsOfUseLinkType.learnMore.url)
        XCTAssertNotNil(TermsOfUseLinkType.here.url)
    }

    func testActionTypes_AreCorrect() {
        XCTAssertEqual(TermsOfUseLinkType.termsOfUse.actionType, .termsLinkTapped)
        XCTAssertEqual(TermsOfUseLinkType.privacyNotice.actionType, .privacyLinkTapped)
        XCTAssertEqual(TermsOfUseLinkType.learnMore.actionType, .learnMoreLinkTapped)
        XCTAssertEqual(TermsOfUseLinkType.here.actionType, .learnMoreLinkTapped)
    }

    func testLinkType_ForURL_ReturnsCorrectType() {
        guard let termsURL = TermsOfUseLinkType.termsOfUse.url else {
            XCTFail("Terms of Use URL should not be nil")
            return
        }
        XCTAssertEqual(TermsOfUseLinkType.linkType(for: termsURL), .termsOfUse)

        let unknownURL = URL(string: "https://example.com/unknown")!
        XCTAssertNil(TermsOfUseLinkType.linkType(for: unknownURL))
    }

    func testHereLink_HasSameURLAsLearnMore() {
        guard let learnMoreURL = TermsOfUseLinkType.learnMore.url,
              let hereURL = TermsOfUseLinkType.here.url else {
            XCTFail("Learn more and here URLs should not be nil")
            return
        }
        XCTAssertEqual(learnMoreURL, hereURL, "here link should have the same URL as Learn more")
    }
}
