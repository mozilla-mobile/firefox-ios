// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import XCTest

@testable import Client

final class WebCompatReportPayloadTests: XCTestCase {
    func testMake_emptyURLAndDetails_stayNil() {
        let payload = WebCompatReportPayload.make(from: makeState(url: "", additionalDetails: ""))

        XCTAssertNil(payload.url)
        XCTAssertNil(payload.description)
    }

    func testMake_subOption_winsOverCategory() {
        let state = makeState(selectedCategory: .videoOrAudio, selectedSubOptionID: "no_audio")

        let payload = WebCompatReportPayload.make(from: state)

        XCTAssertEqual(payload.breakageCategory, "no_audio")
    }

    func testMake_categoryWithoutSubOption_usesCategory() {
        let state = makeState(selectedCategory: .siteNotUsable, selectedSubOptionID: nil)

        let payload = WebCompatReportPayload.make(from: state)

        XCTAssertEqual(payload.breakageCategory, WebCompatIssueCategory.siteNotUsable.rawValue)
    }

    func testMake_noCategorySelected_leavesBreakageCategoryNil() {
        let payload = WebCompatReportPayload.make(from: makeState())

        XCTAssertNil(payload.breakageCategory)
    }

    // MARK: - Helpers

    private func makeState(
        url: String = "",
        selectedCategory: WebCompatIssueCategory? = nil,
        selectedSubOptionID: String? = nil,
        additionalDetails: String = ""
    ) -> WebCompatReporterState {
        return WebCompatReporterState(
            windowUUID: .XCTestDefaultUUID,
            url: url,
            selectedCategory: selectedCategory,
            selectedSubOptionID: selectedSubOptionID,
            additionalDetails: additionalDetails,
            includeScreenshot: true,
            includeBlockedList: false
        )
    }
}
