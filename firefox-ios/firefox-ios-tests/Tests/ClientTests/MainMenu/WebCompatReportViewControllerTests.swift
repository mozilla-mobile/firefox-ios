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
        XCTAssertEqual(lastViewAction()?.actionType as? WebCompatReporterViewActionType, .learnMore)
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

        subject.webCompatReportSheetDidToggleCheckbox(id: "includeScreenshot", isChecked: false)

        let action = lastViewAction()
        XCTAssertEqual(action?.actionType as? WebCompatReporterViewActionType, .toggleScreenshot)
        XCTAssertEqual(action?.includeScreenshot, false)
    }

    func testDidToggle_onBlockedListRow_dispatchesToggleBlockedListWithValue() {
        let subject = createSubject(reportedURL: nil)

        subject.webCompatReportSheetDidToggleCheckbox(id: "includeBlockedList", isChecked: true)

        let action = lastViewAction()
        XCTAssertEqual(action?.actionType as? WebCompatReporterViewActionType, .toggleBlockedList)
        XCTAssertEqual(action?.includeBlockedList, true)
    }

    func testDidToggle_onSendRow_dispatchesNothing() {
        let subject = createSubject(reportedURL: nil)

        subject.webCompatReportSheetDidToggleCheckbox(id: "send", isChecked: true)

        XCTAssertTrue(dispatchedViewActions().isEmpty)
    }

    func testDidToggle_onUnhandledRow_dispatchesNothing() {
        let subject = createSubject(reportedURL: nil)

        subject.webCompatReportSheetDidToggleCheckbox(id: "unknown", isChecked: true)

        XCTAssertTrue(dispatchedViewActions().isEmpty)
    }

    func testDidEditText_onURLRow_dispatchesEditURLWithText() {
        let subject = createSubject(reportedURL: nil)

        subject.webCompatReportSheetDidEditText(id: "url", text: "https://changed.example.com")

        let action = lastViewAction()
        XCTAssertEqual(action?.actionType as? WebCompatReporterViewActionType, .editURL)
        XCTAssertEqual(action?.url, "https://changed.example.com")
    }

    func testDidEditText_onDetailsRow_dispatchesSetAdditionalDetailsWithText() {
        let subject = createSubject(reportedURL: nil)

        subject.webCompatReportSheetDidEditText(id: "additionalDetails", text: "Images never load")

        let action = lastViewAction()
        XCTAssertEqual(action?.actionType as? WebCompatReporterViewActionType, .setAdditionalDetails)
        XCTAssertEqual(action?.additionalDetails, "Images never load")
    }

    func testDidEditText_onNonTextRow_dispatchesNothing() {
        let subject = createSubject(reportedURL: nil)

        subject.webCompatReportSheetDidEditText(id: "send", text: "ignored")

        XCTAssertTrue(dispatchedViewActions().isEmpty)
    }

    func testDidTapPreview_onlyDispatches() {
        let coordinator = MockWebCompatReportCoordinatorDelegate()
        let subject = createSubject(reportedURL: nil)
        subject.reportCoordinator = coordinator
        subject.loadViewIfNeeded()

        subject.webCompatReportSheetDidTapPreview()

        // Building a payload here is what let preview and submit drift.
        XCTAssertEqual(lastViewAction()?.actionType as? WebCompatReporterViewActionType, .preview)
        XCTAssertTrue(coordinator.didTapPreviewPayloads.isEmpty)
    }

    func testNewState_withPreviewPayload_handsItToTheCoordinator() throws {
        let coordinator = MockWebCompatReportCoordinatorDelegate()
        let subject = createSubject(reportedURL: nil)
        subject.reportCoordinator = coordinator
        subject.loadViewIfNeeded()
        var payload = WebCompatReportPayload()
        payload.url = "https://example.com"

        subject.newState(state: WebCompatReporterState(windowUUID: windowUUID)
            .copy(url: "https://example.com")
            .copy(selectedCategory: .videoOrAudio)
            .copy(previewPayload: payload))

        XCTAssertEqual(coordinator.didTapPreviewPayloads, [payload])
    }

    func testNewState_withoutPreviewPayload_leavesTheCoordinatorAlone() {
        let coordinator = MockWebCompatReportCoordinatorDelegate()
        let subject = createSubject(reportedURL: nil)
        subject.reportCoordinator = coordinator
        subject.loadViewIfNeeded()

        subject.newState(state: WebCompatReporterState(windowUUID: windowUUID)
            .copy(url: "https://example.com")
            .copy(selectedCategory: .videoOrAudio))

        XCTAssertTrue(coordinator.didTapPreviewPayloads.isEmpty)
    }

    func testSimpleCreation_hasNoLeaks() {
        let subject = createSubject(reportedURL: nil)
        subject.loadViewIfNeeded()
        trackForMemoryLeaks(subject)
    }

    // MARK: - makeIssueSections

    func testMakeIssueSections_withoutCategory_showsPlaceholderAndNoSubOptions() {
        let state = WebCompatReporterState(windowUUID: windowUUID).copy(url: "https://example.com")

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
        let state = WebCompatReporterState(windowUUID: windowUUID)
            .copy(url: "https://example.com")
            .copy(selectedCategory: .siteNotUsable)
            .copy(selectedSubOptionID: WebCompatSubOption.pageNotLoading.rawValue)

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
        let state = WebCompatReporterState(windowUUID: windowUUID)
            .copy(url: "https://example.com")
            .copy(selectedCategory: .other)

        let sections = WebCompatReportViewController.makeIssueSections(from: state)

        XCTAssertEqual(sections.count, 1)
    }

    // MARK: - makeSections

    func testMakeSections_withoutCategory_showsURLCategoryAdvancedAndDisabledSend() {
        let state = WebCompatReporterState(windowUUID: windowUUID).copy(url: "https://example.com")

        let sections = WebCompatReportViewController.makeSections(from: state)

        // No sub-options and no details until a category is picked.
        XCTAssertEqual(sections.map(\.id), ["url", "issueCategory", "advancedOptions", "send"])

        let advanced = sections.first { $0.id == "advancedOptions" }
        XCTAssertEqual(advanced?.rows.map(\.kind), [.checkbox(isChecked: true)])
        XCTAssertEqual(sections.last?.rows.map(\.kind), [.sendButton(isEnabled: false)])

        guard case let .urlField(text, errorMessage) = sections.first?.rows.first?.kind else {
            return XCTFail("Expected a URL field row")
        }
        XCTAssertEqual(text, "https://example.com")
        XCTAssertNil(errorMessage)
    }

    func testMakeSections_withAnUnreportableURL_carriesTheErrorAndDisablesSend() throws {
        let state = WebCompatReporterState(windowUUID: windowUUID)
            .copy(url: ".com")
            .copy(selectedCategory: .other)

        let sections = WebCompatReportViewController.makeSections(from: state)

        guard case let .urlField(text, errorMessage) = sections.first?.rows.first?.kind else {
            return XCTFail("Expected a URL field row")
        }
        XCTAssertEqual(text, ".com")
        XCTAssertEqual(errorMessage, .WebCompatReporter.Fields.URLError)
        XCTAssertEqual(sections.last?.rows.map(\.kind), [.sendButton(isEnabled: false)])

        let cleared = WebCompatReportViewController.makeSections(
            from: WebCompatReporterState(windowUUID: windowUUID)
                .copy(url: "")
                .copy(selectedCategory: .other)
        )
        guard case let .urlField(_, clearedError) = cleared.first?.rows.first?.kind else {
            return XCTFail("Expected a URL field row")
        }
        XCTAssertNil(clearedError)
    }

    func testMakeSections_withCategory_addsSubOptionsDetailsAndAdvancedWithSendLast() {
        let state = WebCompatReporterState(windowUUID: windowUUID)
            .copy(url: "https://example.com")
            .copy(selectedCategory: .siteNotUsable)
            .copy(selectedSubOptionID: WebCompatSubOption.pageNotLoading.rawValue)
            .copy(additionalDetails: "Broken images")
            .copy(includeScreenshot: false)
            .copy(includeBlockedList: true)

        let sections = WebCompatReportViewController.makeSections(from: state)

        XCTAssertEqual(
            sections.map(\.id),
            ["url", "issueCategory", "issueSubOptions", "additionalDetails", "advancedOptions", "send"]
        )

        let advanced = sections.first { $0.id == "advancedOptions" }
        XCTAssertEqual(advanced?.rows.map(\.kind), [.checkbox(isChecked: true)])
        XCTAssertEqual(sections.last?.rows.map(\.kind), [.sendButton(isEnabled: true)])

        let details = sections.first { $0.id == "additionalDetails" }
        guard case let .detailsField(text, _) = details?.rows.first?.kind else {
            return XCTFail("Expected a details field row")
        }
        XCTAssertEqual(text, "Broken images")
    }

    func testMakeSections_detailsRowLabelsItselfOptional() {
        let state = WebCompatReporterState(windowUUID: windowUUID)
            .copy(url: "https://example.com")
            .copy(selectedCategory: .siteNotUsable)

        let sections = WebCompatReportViewController.makeSections(from: state)

        let details = sections.first { $0.id == "additionalDetails" }
        XCTAssertEqual(details?.rows.first?.title, .WebCompatReporter.Fields.DetailsPlaceholder)
    }

    func testMakeSections_attachesLearnMoreFooterWithATappableLink() throws {
        let state = WebCompatReporterState(windowUUID: windowUUID).copy(url: "https://example.com")

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
    var didSubmitCallCount = 0
    var didTapLearnMoreURLs: [URL] = []
    var didTapPreviewPayloads: [WebCompatReportPayload] = []

    func webCompatReportViewControllerDidFinish() {
        didFinishCallCount += 1
    }

    func webCompatReportViewControllerDidSubmit() {
        didSubmitCallCount += 1
    }

    func webCompatReportViewControllerDidTapLearnMore(url: URL) {
        didTapLearnMoreURLs.append(url)
    }

    func webCompatReportViewControllerDidTapPreview(payload: WebCompatReportPayload) {
        didTapPreviewPayloads.append(payload)
    }
}
