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

        // A metric missing here leaves the device without ever being shown. Counted off the struct,
        // so a new one fails this until it's given a line.
        let metricCount = Mirror(reflecting: WebCompatReportPayload()).children.count
        let keys = groups.flatMap { group in group.fields.map { "\(group.id.rawValue).\($0.key.rawValue)" } }
        XCTAssertEqual(Set(keys).count, keys.count)
        XCTAssertEqual(keys.count, metricCount)
    }

    func testPreviewGroups_areNamedAndOrderedLikeTheReportSchema() {
        // Labelled with the raw schema keys, so a renamed or reordered group misdescribes the ping.
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

    // MARK: - makeTechnicalDataViewModel

    func testMakeTechnicalDataViewModel_showsTheCollectedPayloadNotASecondCopyOfIt() throws {
        var payload = WebCompatReportPayload()
        payload.url = "https://example.com"
        payload.breakageCategory = WebCompatSubOption.pageNotLoading.rawValue
        payload.description = "video never starts"
        payload.isPrivateBrowsing = true
        payload.memory = 8192
        payload.defaultLocales = ["en-GB", "fr"]

        let viewModel = payload.makeTechnicalDataViewModel()

        // Groups and labels come from the payload, so a new metric shows up without touching this file.
        XCTAssertEqual(viewModel.sections.map(\.id), payload.previewGroups.map(\.id.rawValue))
        let rendered = viewModel.sections.flatMap { section in
            section.rows.map { "\(section.id).\($0.label) = \($0.value.displayText)" }
        }
        XCTAssertTrue(rendered.contains("basic.url = \"https://example.com\""))
        XCTAssertTrue(rendered.contains("basic.reason = \"\(WebCompatSubOption.pageNotLoading.rawValue)\""))
        XCTAssertTrue(rendered.contains("antiTracking.isPrivateBrowsing = true"))
        XCTAssertTrue(rendered.contains("system.memory = 8192"))
        XCTAssertTrue(rendered.contains("app.defaultLocales = [\"en-GB\", \"fr\"]"))
    }

    func testMakeTechnicalDataViewModel_uncollectedMetricsReadAsNull() throws {
        // What the form knows on its own; everything the collector fills in is still missing.
        let payload = WebCompatReportPayload.make(
            from: makeState(url: "https://example.com", selectedCategory: .other)
        )

        let viewModel = payload.makeTechnicalDataViewModel()

        let frameworks = try XCTUnwrap(viewModel.sections.first { $0.id == "frameworks" })
        XCTAssertEqual(frameworks.rows.map { $0.value.displayText }, ["null", "null", "null"])
        // An empty details field is absent from the report, so it reads `null` rather than `""`.
        let description = try XCTUnwrap(
            viewModel.sections.first { $0.id == "basic" }?.rows.first { $0.label == "description" }
        )
        XCTAssertEqual(description.value, .null)
    }

    func testMakeTechnicalDataViewModel_givesEveryGroupItsOwnAccessibilityIdentifiers() {
        let viewModel = WebCompatReportPayload().makeTechnicalDataViewModel()

        // Header and card are addressed separately in UI tests, so they can't share an identifier.
        let identifiers = viewModel.sections.flatMap { [$0.a11yIdentifier, $0.contentA11yIdentifier] }
        XCTAssertEqual(Set(identifiers).count, identifiers.count)
        XCTAssertTrue(identifiers.allSatisfy { $0.hasPrefix("WebCompatReporter.Preview.") })
    }

    // MARK: - makeReportPreviewViewModel

    func testMakeReportPreviewViewModel_titlesTheScreenAndTheRowFromDifferentStrings() {
        let viewModel = WebCompatReportPayload().makeReportPreviewViewModel()

        XCTAssertEqual(viewModel.title, .WebCompatReporter.Preview.Title)
        XCTAssertEqual(viewModel.technicalDataTitle, .WebCompatReporter.Preview.TechnicalData)
    }

    // The summary can't claim data the report doesn't carry, and the order is the design's.
    func testMakeReportPreviewViewModel_bulletsCoverOnlyCollectedFields() {
        var payload = WebCompatReportPayload()
        payload.url = "https://example.com"
        payload.breakageCategory = WebCompatSubOption.pageNotLoading.rawValue

        let bullets = payload.makeReportPreviewViewModel().bullets

        XCTAssertEqual(bullets, [
            "\(String.WebCompatReporter.Preview.Data.PageURL)\u{2028}[https://example.com]",
            .WebCompatReporter.Preview.Data.IssueAndDescription
        ])
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
