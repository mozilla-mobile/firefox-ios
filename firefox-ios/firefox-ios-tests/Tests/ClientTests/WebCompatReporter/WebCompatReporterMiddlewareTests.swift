// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Glean
import Redux
import TestKit
import XCTest

@testable import Client

@MainActor
final class WebCompatReporterMiddlewareTests: XCTestCase, StoreTestUtility {
    private var mockStore: MockStoreForMiddleware<AppState>!
    private var gleanWrapper: MockGleanWrapper!

    override func setUp() async throws {
        try await super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        gleanWrapper = MockGleanWrapper()
        setupStore()
    }

    override func tearDown() async throws {
        DependencyHelperMock().reset()
        gleanWrapper = nil
        resetStore()
        try await super.tearDown()
    }

    // MARK: - viewDidLoad

    func test_viewDidLoad_dispatchesDidLoadInitialDraftWithURL() throws {
        let subject = createSubject()
        let action = WebCompatReporterViewAction(
            url: "https://example.com",
            windowUUID: .XCTestDefaultUUID,
            actionType: WebCompatReporterViewActionType.viewDidLoad
        )

        subject.webCompatReporterProvider.legacyMiddleware(mockStore.state, action)

        XCTAssertEqual(mockStore.dispatchedActions.count, 1)
        let dispatched = try XCTUnwrap(mockStore.dispatchedActions.first as? WebCompatReporterMiddlewareAction)
        let dispatchedType = try XCTUnwrap(dispatched.actionType as? WebCompatReporterMiddlewareActionType)
        XCTAssertEqual(dispatchedType, WebCompatReporterMiddlewareActionType.didLoadInitialDraft)
        XCTAssertEqual(dispatched.url, "https://example.com")

        releaseMiddlewareProvidersFromMemory(subject)
    }

    // MARK: - submit

    func test_submit_submitsThePingAndDispatchesDidSubmit() throws {
        let subject = createSubject()

        subject.webCompatReporterProvider.legacyMiddleware(mockStore.state, submitAction())

        XCTAssertEqual(gleanWrapper.submitPingCalled, 1)
        XCTAssertEqual(mockStore.dispatchedActions.count, 1)
        let dispatched = try XCTUnwrap(mockStore.dispatchedActions.first as? WebCompatReporterMiddlewareAction)
        let dispatchedType = try XCTUnwrap(dispatched.actionType as? WebCompatReporterMiddlewareActionType)
        XCTAssertEqual(dispatchedType, WebCompatReporterMiddlewareActionType.didSubmit)

        releaseMiddlewareProvidersFromMemory(subject)
    }

    // MARK: - Tab-specific info

    func test_submit_whenURLStillMatchesTheTab_includesTabFields() {
        let subject = createSubject(selectedTab: makeTab(url: "https://example.com/page"))
        setReportedURL("https://example.com/page")

        subject.webCompatReporterProvider.legacyMiddleware(mockStore.state, submitAction())

        // is_private_browsing on top of the device's has_touch_screen and is_tablet.
        XCTAssertEqual(gleanWrapper.setBooleanCalled, 3)

        releaseMiddlewareProvidersFromMemory(subject)
    }

    func test_submit_whenURLNoLongerMatchesTheTab_dropsTabFields() {
        let subject = createSubject(selectedTab: makeTab(url: "https://example.com/page"))
        setReportedURL("https://different.example/other")

        subject.webCompatReporterProvider.legacyMiddleware(mockStore.state, submitAction())

        XCTAssertEqual(gleanWrapper.setBooleanCalled, 2)

        releaseMiddlewareProvidersFromMemory(subject)
    }

    // MARK: - preview

    func test_preview_dispatchesDidBuildPreviewWithTheReport() throws {
        let subject = createSubject(selectedTab: makeTab(url: "https://example.com/page"))
        setReportedURL("https://example.com/page")

        subject.webCompatReporterProvider.legacyMiddleware(mockStore.state, viewAction(.preview))

        let dispatched = try XCTUnwrap(mockStore.dispatchedActions.first as? WebCompatReporterMiddlewareAction)
        let dispatchedType = try XCTUnwrap(dispatched.actionType as? WebCompatReporterMiddlewareActionType)
        XCTAssertEqual(dispatchedType, WebCompatReporterMiddlewareActionType.didBuildPreview)
        let payload = try XCTUnwrap(dispatched.previewPayload)
        XCTAssertEqual(payload.url, "https://example.com/page")
        XCTAssertEqual(payload.isPrivateBrowsing, false)

        releaseMiddlewareProvidersFromMemory(subject)
    }

    func test_preview_whenURLNoLongerMatchesTheTab_dropsTabFieldsLikeSubmit() throws {
        // The preview has to drop exactly what the ping drops.
        let subject = createSubject(selectedTab: makeTab(url: "https://example.com/page"))
        setReportedURL("https://different.example/other")

        subject.webCompatReporterProvider.legacyMiddleware(mockStore.state, viewAction(.preview))

        let dispatched = try XCTUnwrap(mockStore.dispatchedActions.first as? WebCompatReporterMiddlewareAction)
        let payload = try XCTUnwrap(dispatched.previewPayload)
        XCTAssertNil(payload.isPrivateBrowsing)
        XCTAssertNil(payload.blockList)
        XCTAssertNil(payload.userAgentString)

        releaseMiddlewareProvidersFromMemory(subject)
    }

    // MARK: - Pure view actions are not handled by the middleware

    func test_selectCategory_doesNotDispatchViaMiddleware() {
        let subject = createSubject()
        let action = WebCompatReporterViewAction(
            category: .siteNotUsable,
            windowUUID: .XCTestDefaultUUID,
            actionType: WebCompatReporterViewActionType.selectCategory
        )

        subject.webCompatReporterProvider.legacyMiddleware(mockStore.state, action)

        XCTAssertEqual(mockStore.dispatchedActions.count, 0)

        releaseMiddlewareProvidersFromMemory(subject)
    }

    // MARK: - Telemetry

    func test_selectCategory_recordsReasonSelectedWithTheCategory() throws {
        let subject = createSubject()
        let action = WebCompatReporterViewAction(
            category: .videoOrAudio,
            windowUUID: .XCTestDefaultUUID,
            actionType: WebCompatReporterViewActionType.selectCategory
        )

        subject.webCompatReporterProvider.legacyMiddleware(mockStore.state, action)

        let event = GleanMetrics.BrokenSiteReportInteractions.reasonSelected
        let savedExtras = try XCTUnwrap(
            gleanWrapper.savedExtras.first as? GleanMetrics.BrokenSiteReportInteractions.ReasonSelectedExtra
        )
        let savedMetric = try XCTUnwrap(
            gleanWrapper.savedEvents.first
                as? EventMetricType<GleanMetrics.BrokenSiteReportInteractions.ReasonSelectedExtra>
        )

        XCTAssertEqual(gleanWrapper.recordEventCalled, 1)
        XCTAssertEqual(savedExtras.reason, WebCompatIssueCategory.videoOrAudio.rawValue)
        XCTAssert(savedMetric === event, "Received \(savedMetric) instead of \(event)")

        releaseMiddlewareProvidersFromMemory(subject)
    }

    func test_preview_recordsPreviewed() {
        let subject = createSubject()

        subject.webCompatReporterProvider.legacyMiddleware(mockStore.state, viewAction(.preview))

        XCTAssertEqual(gleanWrapper.recordEventNoExtraCalled, 1)
        XCTAssertTrue(savedNoExtraEvent(is: GleanMetrics.BrokenSiteReportInteractions.previewed))

        releaseMiddlewareProvidersFromMemory(subject)
    }

    func test_cancel_recordsCancelled() {
        let subject = createSubject()

        subject.webCompatReporterProvider.legacyMiddleware(mockStore.state, viewAction(.cancel))

        XCTAssertEqual(gleanWrapper.recordEventNoExtraCalled, 1)
        XCTAssertTrue(savedNoExtraEvent(is: GleanMetrics.BrokenSiteReportInteractions.cancelled))

        releaseMiddlewareProvidersFromMemory(subject)
    }

    func test_learnMore_recordsLearnMoreTapped() {
        let subject = createSubject()

        subject.webCompatReporterProvider.legacyMiddleware(mockStore.state, viewAction(.learnMore))

        XCTAssertEqual(gleanWrapper.recordEventNoExtraCalled, 1)
        XCTAssertTrue(savedNoExtraEvent(is: GleanMetrics.BrokenSiteReportInteractions.learnMoreTapped))

        releaseMiddlewareProvidersFromMemory(subject)
    }

    func test_submit_recordsCreatedCarryingTheBlockedListChoice() throws {
        let subject = createSubject()
        setIncludeBlockedList(true)

        subject.webCompatReporterProvider.legacyMiddleware(mockStore.state, submitAction())

        let savedExtras = try XCTUnwrap(createdExtras())
        XCTAssertEqual(savedExtras.hasBlockedTrackersList, true)

        releaseMiddlewareProvidersFromMemory(subject)
    }

    func test_submit_whenStateWantsAScreenshot_stillRecordsCreatedWithoutOne() throws {
        let subject = createSubject()
        XCTAssertTrue(WebCompatReporterState(windowUUID: .XCTestDefaultUUID).includeScreenshot)

        subject.webCompatReporterProvider.legacyMiddleware(mockStore.state, submitAction())

        let savedExtras = try XCTUnwrap(createdExtras())
        XCTAssertEqual(savedExtras.hasScreenshot, false)
        XCTAssertEqual(savedExtras.hasBlockedTrackersList, false)

        releaseMiddlewareProvidersFromMemory(subject)
    }

    // MARK: - Unrelated action

    func test_unrelatedAction_doesNotDispatch() {
        let subject = createSubject()
        let action = WebCompatReporterMiddlewareAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: WebCompatReporterMiddlewareActionType.didLoadInitialDraft
        )

        subject.webCompatReporterProvider.legacyMiddleware(mockStore.state, action)

        XCTAssertEqual(mockStore.dispatchedActions.count, 0)

        releaseMiddlewareProvidersFromMemory(subject)
    }

    // MARK: - StoreTestUtility

    func setupAppState() -> AppState {
        return AppState(
            presentedComponents: PresentedComponentsState(
                components: [
                    .webCompatReporter(WebCompatReporterState(windowUUID: .XCTestDefaultUUID))
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

    // MARK: - Helpers

    private func submitAction() -> WebCompatReporterViewAction {
        return WebCompatReporterViewAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: WebCompatReporterViewActionType.submit
        )
    }

    private func viewAction(_ actionType: WebCompatReporterViewActionType) -> WebCompatReporterViewAction {
        return WebCompatReporterViewAction(windowUUID: .XCTestDefaultUUID, actionType: actionType)
    }

    private func savedNoExtraEvent(is event: EventMetricType<NoExtras>) -> Bool {
        return gleanWrapper.savedEvents.contains { ($0 as? EventMetricType<NoExtras>) === event }
    }

    private func createdExtras() -> GleanMetrics.BrokenSiteReportInteractions.CreatedExtra? {
        return gleanWrapper.savedExtras.compactMap {
            $0 as? GleanMetrics.BrokenSiteReportInteractions.CreatedExtra
        }.first
    }

    private func setIncludeBlockedList(_ includeBlockedList: Bool) {
        mockStore.state = AppState(
            presentedComponents: PresentedComponentsState(
                components: [
                    .webCompatReporter(
                        WebCompatReporterState(
                            windowUUID: .XCTestDefaultUUID,
                            url: "https://example.com",
                            includeBlockedList: includeBlockedList
                        )
                    )
                ]
            )
        )
    }

    private func makeTab(url: String) -> Tab {
        let tab = Tab(profile: MockProfile(), windowUUID: .XCTestDefaultUUID)
        tab.url = URL(string: url)
        return tab
    }

    private func setReportedURL(_ url: String) {
        mockStore.state = AppState(
            presentedComponents: PresentedComponentsState(
                components: [
                    .webCompatReporter(
                        WebCompatReporterState(windowUUID: .XCTestDefaultUUID, url: url)
                    )
                ]
            )
        )
    }

    private func createSubject(selectedTab: Tab? = nil) -> WebCompatReporterMiddleware {
        let tabManager = MockTabManager()
        tabManager.selectedTab = selectedTab
        let subject = WebCompatReporterMiddleware(
            windowManager: MockWindowManager(
                wrappedManager: WindowManagerImplementation(),
                tabManager: tabManager
            ),
            recorder: WebCompatReportRecorder(gleanWrapper: gleanWrapper),
            telemetry: WebCompatReporterTelemetry(gleanWrapper: gleanWrapper)
        )
        trackForMemoryLeaks(subject)
        return subject
    }

    /// Our middleware providers always retain a strong reference to `self` for ease of use. Thus, `trackForMemoryLeaks` will
    /// fail in our unit tests due to a strong circular reference to the middleware retained by its provider closures. In
    /// practice, this is not a memory leak issue, as we permanently allocate and retain our middleware providers for the
    /// entire app lifecycle.
    ///
    /// As a work around for unit tests, we should release each middleware's provider closures from memory by assigning an
    /// empty closure, which does not strongly retain `self`.
    private func releaseMiddlewareProvidersFromMemory(_ subject: WebCompatReporterMiddleware) {
        subject.webCompatReporterProvider = emptyMiddlewareProviderFactory()
        subject.legacyProvider = emptyLegacyMiddlewareFactory()
        subject.modernProvider = emptyMiddlewareFactory()
    }
}
