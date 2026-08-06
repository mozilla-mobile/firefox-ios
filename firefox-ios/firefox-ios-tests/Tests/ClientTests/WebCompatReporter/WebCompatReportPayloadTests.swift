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

    // MARK: - previewGroups

    func testPreviewGroups_coverEveryMetricExactlyOnce() {
        let groups = WebCompatReportPayload().previewGroups

        // The preview is the user's account of what gets sent, so a metric missing from these
        // groups is one that leaves the device without ever being shown. Counted off the struct
        // rather than hardcoded, so adding a metric fails here until it's given a line.
        let metricCount = Mirror(reflecting: WebCompatReportPayload()).children.count
        let keys = groups.flatMap { group in group.fields.map { "\(group.id.rawValue).\($0.key.rawValue)" } }
        XCTAssertEqual(Set(keys).count, keys.count)
        XCTAssertEqual(keys.count, metricCount)
    }

    func testPreviewGroups_areNamedAndOrderedLikeTheReportSchema() {
        // The sections are labelled with the raw `broken-site-report` keys, so a group named or
        // ordered differently from the schema misdescribes the ping the user is agreeing to send.
        XCTAssertEqual(
            WebCompatReportPayload().previewGroups.map(\.id.rawValue),
            ["basic", "tabInfo", "antiTracking", "frameworks", "app", "system", "graphics"]
        )
    }

    func testPreviewGroups_uncollectedMetricsReadAsNull() {
        let groups = WebCompatReportPayload().previewGroups

        let values = groups.flatMap { $0.fields.map { $0.value.displayText } }
        XCTAssertTrue(values.allSatisfy { $0 == "null" })
    }

    func testPreviewGroups_renderEachTypeTheWayTheReportSpellsIt() {
        var payload = WebCompatReportPayload()
        payload.url = "https://example.com"
        payload.isPrivateBrowsing = false
        payload.memory = 4096
        payload.defaultLocales = ["en-GB", "fr"]

        let rendered = renderedFields(of: payload)

        XCTAssertEqual(rendered["basic.url"], "\"https://example.com\"")
        XCTAssertEqual(rendered["antiTracking.isPrivateBrowsing"], "false")
        XCTAssertEqual(rendered["system.memory"], "4096")
        XCTAssertEqual(rendered["app.defaultLocales"], "[\"en-GB\", \"fr\"]")
    }

    func testPreviewGroups_optedInWithNothingBlocked_showsAnEmptyListNotNull() {
        var payload = WebCompatReportPayload()
        payload.blockedOrigins = []

        // "We looked and found none" is a different answer from "we didn't look".
        XCTAssertEqual(renderedFields(of: payload)["antiTracking.blockedOrigins"], "[]")
    }

    // MARK: - Helpers

    private func renderedFields(of payload: WebCompatReportPayload) -> [String: String] {
        return Dictionary(
            uniqueKeysWithValues: payload.previewGroups.flatMap { group in
                group.fields.map { ("\(group.id.rawValue).\($0.key.rawValue)", $0.value.displayText) }
            }
        )
    }

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
