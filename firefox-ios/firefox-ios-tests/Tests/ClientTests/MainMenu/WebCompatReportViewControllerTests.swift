// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import WebCompatReporterKit
import XCTest

@testable import Client

@MainActor
final class WebCompatReportViewControllerTests: XCTestCase {
    let windowUUID: WindowUUID = .XCTestDefaultUUID

    override func setUp() async throws {
        try await super.setUp()
        DependencyHelperMock().bootstrapDependencies()
    }

    override func tearDown() async throws {
        DependencyHelperMock().reset()
        try await super.tearDown()
    }

    func testViewDidLoad_hostsSheetAsSingleRootViewController() {
        let subject = createSubject(reportedURL: URL(string: "https://example.com"))

        subject.loadViewIfNeeded()

        XCTAssertEqual(subject.viewControllers.count, 1)
        XCTAssertTrue(subject.viewControllers.first is WebCompatReportSheetViewController)
    }

    func testDidTapClose_notifiesCoordinatorToDismiss() {
        let coordinator = MockWebCompatReportCoordinatorDelegate()
        let subject = createSubject(reportedURL: nil)
        subject.reportCoordinator = coordinator
        subject.loadViewIfNeeded()

        subject.webCompatReportSheetDidTapClose()

        XCTAssertEqual(coordinator.didFinishCallCount, 1)
    }

    func testDidTapLearnMore_notifiesCoordinator() {
        let coordinator = MockWebCompatReportCoordinatorDelegate()
        let subject = createSubject(reportedURL: nil)
        subject.reportCoordinator = coordinator
        subject.loadViewIfNeeded()

        subject.webCompatReportSheetDidTapLearnMore()

        XCTAssertEqual(coordinator.didTapLearnMoreCallCount, 1)
        XCTAssertEqual(coordinator.didFinishCallCount, 0)
    }

    func testSimpleCreation_hasNoLeaks() {
        let subject = createSubject(reportedURL: nil)
        subject.loadViewIfNeeded()
        trackForMemoryLeaks(subject)
    }

    // MARK: - makeIssueSections

    func testMakeIssueSections_withoutCategory_showsPlaceholderAndNoSubOptions() {
        let state = WebCompatReporterState(windowUUID: windowUUID, url: "https://example.com")

        let sections = WebCompatReportViewController.makeIssueSections(from: state)

        XCTAssertEqual(sections.count, 1)
        XCTAssertEqual(sections.first?.title, .WebCompatReporter.IssueSection.Title)
        XCTAssertEqual(sections.first?.rows.first?.title, .WebCompatReporter.IssueSection.CategoryPlaceholder)
        guard case let .categoryMenu(isPlaceholder, options) = sections.first?.rows.first?.kind else {
            return XCTFail("Expected a category menu row")
        }
        XCTAssertTrue(isPlaceholder)
        XCTAssertEqual(options.count, WebCompatIssueCategory.allCases.count)
        XCTAssertTrue(options.allSatisfy { !$0.isSelected })
    }

    func testMakeIssueSections_withCategory_addsSubOptionsWithCheckmarkOnSelected() {
        let state = WebCompatReporterState(
            windowUUID: windowUUID,
            url: "https://example.com",
            selectedCategory: .siteNotUsable,
            selectedSubOptionID: WebCompatSubOption.pageNotLoading.rawValue
        )

        let sections = WebCompatReportViewController.makeIssueSections(from: state)

        XCTAssertEqual(sections.count, 2)
        XCTAssertEqual(sections[0].rows.first?.title, .WebCompatReporter.Category.SiteNotUsable)
        guard case let .categoryMenu(isPlaceholder, options) = sections[0].rows.first?.kind else {
            return XCTFail("Expected a category menu row")
        }
        XCTAssertFalse(isPlaceholder)
        XCTAssertEqual(options.first { $0.isSelected }?.id, WebCompatIssueCategory.siteNotUsable.id)

        let subOptionRows = sections[1].rows
        XCTAssertEqual(subOptionRows.map(\.id), WebCompatIssueCategory.siteNotUsable.subOptions.map(\.rawValue))
        let selectedRows = subOptionRows.filter { $0.kind == .subOption(isSelected: true) }
        XCTAssertEqual(selectedRows.map(\.id), [WebCompatSubOption.pageNotLoading.rawValue])
    }

    func testMakeIssueSections_withOtherCategory_hasNoSubOptionSection() {
        let state = WebCompatReporterState(
            windowUUID: windowUUID,
            url: "https://example.com",
            selectedCategory: .other
        )

        let sections = WebCompatReportViewController.makeIssueSections(from: state)

        XCTAssertEqual(sections.count, 1)
    }

    // MARK: - makeSections

    func testMakeSections_withoutCategory_omitsDetailsAndDisablesSend() {
        let state = WebCompatReporterState(windowUUID: windowUUID, url: "https://example.com")

        let sections = WebCompatReportViewController.makeSections(from: state)

        // URL + category + advanced + send (no sub-options, no details).
        XCTAssertEqual(sections.map(\.id), ["url", "issueCategory", "advancedOptions", "send"])

        guard case let .urlField(text, _) = sections.first?.rows.first?.kind else {
            return XCTFail("Expected a URL field row")
        }
        XCTAssertEqual(text, "https://example.com")

        let advanced = sections.first { $0.id == "advancedOptions" }
        XCTAssertNotNil(advanced?.footer)
        XCTAssertEqual(advanced?.footer?.linkText, .WebCompatReporter.AdditionalInfo.LearnMore)
        XCTAssertEqual(advanced?.rows.map(\.kind), [.toggle(isOn: true), .toggle(isOn: false)])

        XCTAssertEqual(sections.last?.rows.first?.kind, .sendButton(isEnabled: false))
    }

    func testMakeSections_withCategory_showsDetailsAndEnablesSend() {
        let state = WebCompatReporterState(
            windowUUID: windowUUID,
            url: "https://example.com",
            selectedCategory: .siteNotUsable,
            selectedSubOptionID: WebCompatSubOption.pageNotLoading.rawValue,
            additionalDetails: "Broken images",
            includeScreenshot: false,
            includeBlockedList: true
        )

        let sections = WebCompatReportViewController.makeSections(from: state)

        XCTAssertEqual(
            sections.map(\.id),
            ["url", "issueCategory", "issueSubOptions", "additionalDetails", "advancedOptions", "send"]
        )

        let details = sections.first { $0.id == "additionalDetails" }
        guard case let .detailsField(text, _) = details?.rows.first?.kind else {
            return XCTFail("Expected a details field row")
        }
        XCTAssertEqual(text, "Broken images")

        let advanced = sections.first { $0.id == "advancedOptions" }
        XCTAssertEqual(advanced?.rows.map(\.kind), [.toggle(isOn: false), .toggle(isOn: true)])

        XCTAssertEqual(sections.last?.rows.first?.kind, .sendButton(isEnabled: true))
    }

    // MARK: - makePreviewViewModel

    func testMakePreviewViewModel_rendersPayloadGroupsWithGleanKeys() {
        let state = WebCompatReporterState(
            windowUUID: windowUUID,
            url: "https://example.com",
            selectedCategory: .siteNotUsable,
            selectedSubOptionID: WebCompatSubOption.pageNotLoading.rawValue,
            additionalDetails: "Broken images"
        )

        let viewModel = WebCompatReportViewController.makePreviewViewModel(from: state)

        XCTAssertEqual(viewModel.title, .WebCompatReporter.Preview.Title)
        XCTAssertNil(viewModel.screenshot)
        XCTAssertFalse(viewModel.showsScreenshot)
        // Sections/keys come straight from WebCompatReportPayload (the Glean-aligned model).
        XCTAssertEqual(
            viewModel.sections.map(\.id),
            ["basic", "tabInfo", "antitracking", "frameworks", "app", "graphics", "system"]
        )

        let basic = viewModel.sections.first { $0.id == "basic" }
        XCTAssertEqual(basic?.rows.map(\.label), ["url", "breakage_category", "description"])
        XCTAssertEqual(basic?.rows.first { $0.id == "basic.url" }?.value, "\"https://example.com\"")
        XCTAssertEqual(
            basic?.rows.first { $0.id == "basic.breakage_category" }?.value,
            "\"\(WebCompatSubOption.pageNotLoading.rawValue)\""
        )
        XCTAssertEqual(basic?.rows.first { $0.id == "basic.description" }?.value, "\"Broken images\"")
        // Not-yet-collected fields render as null.
        XCTAssertEqual(
            viewModel.sections.first { $0.id == "tabInfo" }?.rows.first { $0.id == "tabInfo.languages" }?.value,
            "null"
        )
    }

    // MARK: - WebCompatReportPayload

    func testPayloadMake_populatesOnlyUserSuppliedFields() {
        let state = WebCompatReporterState(
            windowUUID: windowUUID,
            url: "https://example.com",
            selectedCategory: .siteNotUsable,
            selectedSubOptionID: WebCompatSubOption.pageNotLoading.rawValue,
            additionalDetails: "Broken images"
        )

        let payload = WebCompatReportPayload.make(from: state)

        XCTAssertEqual(payload.url, "https://example.com")
        XCTAssertEqual(payload.breakageCategory, WebCompatSubOption.pageNotLoading.rawValue)
        XCTAssertEqual(payload.description, "Broken images")
        XCTAssertNil(payload.languages)
        XCTAssertNil(payload.isPrivateBrowsing)
    }

    func testPayloadMake_emptyFieldsBecomeNil_categoryUsedWhenNoSubOption() {
        let state = WebCompatReporterState(windowUUID: windowUUID, url: "", selectedCategory: .other)

        let payload = WebCompatReportPayload.make(from: state)

        XCTAssertNil(payload.url)
        XCTAssertNil(payload.description)
        XCTAssertEqual(payload.breakageCategory, WebCompatIssueCategory.other.rawValue)
    }

    func testPayloadPreviewGroups_formatsJsonValuesAndNulls() {
        var payload = WebCompatReportPayload()
        payload.url = "https://example.com"
        payload.languages = ["en-US", "fr"]
        payload.mobify = false

        let groups = payload.previewGroups

        func value(_ title: String, _ key: String) -> String? {
            return groups.first { $0.title == title }?.fields.first { $0.key == key }?.value
        }
        XCTAssertEqual(value("basic", "url"), "\"https://example.com\"")
        XCTAssertEqual(value("basic", "description"), "null")
        XCTAssertEqual(value("tabInfo", "languages"), "[\"en-US\", \"fr\"]")
        XCTAssertEqual(value("frameworks", "mobify"), "false")
        XCTAssertEqual(value("system", "memory"), "null")
    }

    func testDidTapPreview_forwardsPayloadToCoordinator() {
        let coordinator = MockWebCompatReportCoordinatorDelegate()
        let subject = createSubject(reportedURL: nil)
        subject.reportCoordinator = coordinator
        subject.loadViewIfNeeded()

        subject.webCompatReportSheetDidTapPreview()

        XCTAssertEqual(coordinator.didTapPreviewPayloads.count, 1)
    }

    private func createSubject(reportedURL: URL?) -> WebCompatReportViewController {
        return WebCompatReportViewController(windowUUID: windowUUID, reportedURL: reportedURL)
    }
}

private final class MockWebCompatReportCoordinatorDelegate: WebCompatReportCoordinatorDelegate {
    var didFinishCallCount = 0
    var didTapLearnMoreCallCount = 0
    var didTapPreviewPayloads: [WebCompatReportPayload] = []

    func webCompatReportViewControllerDidFinish() {
        didFinishCallCount += 1
    }

    func webCompatReportViewControllerDidTapLearnMore() {
        didTapLearnMoreCallCount += 1
    }

    func webCompatReportViewControllerDidTapPreview(_ request: WebCompatPreviewRequest) {
        didTapPreviewPayloads.append(request.payload)
    }
}
