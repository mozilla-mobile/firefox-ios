// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux
import WebCompatReporterKit
import XCTest

@testable import Client

@MainActor
final class WebCompatReportViewControllerTests: XCTestCase, StoreTestUtility {
    let windowUUID: WindowUUID = .XCTestDefaultUUID
    var mockStore: MockStoreForMiddleware<AppState>!

    override func setUp() async throws {
        try await super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        setupStore()
    }

    override func tearDown() async throws {
        DependencyHelperMock().reset()
        resetStore()
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

    // MARK: - Delegate intents → Redux actions

    func testDidTapLearnMore_forwardsURLToCoordinator() throws {
        let learnMoreURL = try XCTUnwrap(URL(string: "https://example.com/learn-more"))
        let coordinator = MockWebCompatReportCoordinatorDelegate()
        let subject = createSubject(reportedURL: nil)
        subject.reportCoordinator = coordinator
        subject.loadViewIfNeeded()

        subject.webCompatReportSheetDidTapLearnMore(url: learnMoreURL)

        XCTAssertEqual(coordinator.didTapLearnMoreURLs, [learnMoreURL])
    }

    func testDidTapButton_onSendRow_dispatchesSubmit() {
        let subject = createSubject(reportedURL: nil)

        subject.webCompatReportSheetDidTapButton(id: "send")

        XCTAssertEqual(lastViewAction()?.actionType as? WebCompatReporterViewActionType, .submit)
    }

    func testDidTapButton_onUnhandledRow_dispatchesNothing() {
        let subject = createSubject(reportedURL: nil)

        subject.webCompatReportSheetDidTapButton(id: "unknown")

        XCTAssertTrue(dispatchedViewActions().isEmpty)
    }

    func testDidToggle_onScreenshotRow_dispatchesToggleScreenshotWithValue() {
        let subject = createSubject(reportedURL: nil)

        subject.webCompatReportSheetDidToggle(id: "includeScreenshot", isOn: false)

        let action = lastViewAction()
        XCTAssertEqual(action?.actionType as? WebCompatReporterViewActionType, .toggleScreenshot)
        XCTAssertEqual(action?.includeScreenshot, false)
    }

    func testDidToggle_onBlockedListRow_dispatchesToggleBlockedListWithValue() {
        let subject = createSubject(reportedURL: nil)

        subject.webCompatReportSheetDidToggle(id: "includeBlockedList", isOn: true)

        let action = lastViewAction()
        XCTAssertEqual(action?.actionType as? WebCompatReporterViewActionType, .toggleBlockedList)
        XCTAssertEqual(action?.includeBlockedList, true)
    }

    func testDidToggle_onSendRow_dispatchesNothing() {
        let subject = createSubject(reportedURL: nil)

        subject.webCompatReportSheetDidToggle(id: "send", isOn: true)

        XCTAssertTrue(dispatchedViewActions().isEmpty)
    }

    func testDidToggle_onUnhandledRow_dispatchesNothing() {
        let subject = createSubject(reportedURL: nil)

        subject.webCompatReportSheetDidToggle(id: "unknown", isOn: true)

        XCTAssertTrue(dispatchedViewActions().isEmpty)
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

    func testMakeSections_withoutCategory_showsAdvancedTogglesAndDisabledSendButton() {
        let state = WebCompatReporterState(windowUUID: windowUUID, url: "https://example.com")

        let sections = WebCompatReportViewController.makeSections(from: state)

        // Category + advanced + send (no sub-options until a category is picked).
        XCTAssertEqual(sections.map(\.id), ["issueCategory", "advancedOptions", "send"])

        let advanced = sections.first { $0.id == "advancedOptions" }
        XCTAssertEqual(advanced?.rows.map(\.kind), [.toggle(isOn: true), .toggle(isOn: false)])
        XCTAssertEqual(sections.last?.rows.map(\.kind), [.sendButton(isEnabled: false)])
    }

    func testMakeSections_withCategory_keepsAdvancedTogglesBeforeSendButton() {
        let state = WebCompatReporterState(
            windowUUID: windowUUID,
            url: "https://example.com",
            selectedCategory: .siteNotUsable,
            selectedSubOptionID: WebCompatSubOption.pageNotLoading.rawValue,
            includeScreenshot: false,
            includeBlockedList: true
        )

        let sections = WebCompatReportViewController.makeSections(from: state)

        XCTAssertEqual(sections.map(\.id), ["issueCategory", "issueSubOptions", "advancedOptions", "send"])

        let advanced = sections.first { $0.id == "advancedOptions" }
        XCTAssertEqual(advanced?.rows.map(\.kind), [.toggle(isOn: false), .toggle(isOn: true)])
        XCTAssertEqual(sections.last?.rows.map(\.kind), [.sendButton(isEnabled: true)])
    }

    func testMakeSections_attachesLearnMoreFooterWithATappableLink() throws {
        let state = WebCompatReporterState(windowUUID: windowUUID, url: "https://example.com")

        let sections = WebCompatReportViewController.makeSections(from: state)

        XCTAssertEqual(sections.filter { $0.footer != nil }.map(\.id), ["advancedOptions"])

        // The footer view locates the link by searching `text` for `linkText`; if the
        // format string and the link string drift apart the link silently stops rendering.
        let footer = try XCTUnwrap(sections.first { $0.id == "advancedOptions" }?.footer)
        XCTAssertTrue(footer.text.contains(footer.linkText))
        XCTAssertNotNil(footer.linkURL)
    }

    private func createSubject(reportedURL: URL?) -> WebCompatReportViewController {
        return WebCompatReportViewController(windowUUID: windowUUID, reportedURL: reportedURL)
    }

    private func dispatchedViewActions() -> [WebCompatReporterViewAction] {
        return mockStore.dispatchedActions.compactMap { $0 as? WebCompatReporterViewAction }
    }

    private func lastViewAction() -> WebCompatReporterViewAction? {
        return dispatchedViewActions().last
    }

    // MARK: - StoreTestUtility

    func setupAppState() -> AppState {
        return AppState(
            presentedComponents: PresentedComponentsState(
                components: [
                    .webCompatReporter(WebCompatReporterState(windowUUID: windowUUID))
                ]
            )
        )
    }

    func setupStore() {
        mockStore = MockStoreForMiddleware(state: setupAppState())
        StoreTestUtilityHelper.setupStore(with: mockStore)
    }

    func resetStore() {
        StoreTestUtilityHelper.resetStore()
    }
}

private final class MockWebCompatReportCoordinatorDelegate: WebCompatReportCoordinatorDelegate {
    var didFinishCallCount = 0
    var didTapLearnMoreURLs: [URL] = []

    func webCompatReportViewControllerDidFinish() {
        didFinishCallCount += 1
    }

    func webCompatReportViewControllerDidTapLearnMore(url: URL) {
        didTapLearnMoreURLs.append(url)
    }
}
