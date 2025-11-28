// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Redux
import XCTest

@testable import Client

final class SummarizerMiddlewareTests: XCTestCase, StoreTestUtility {
    private var mockWindowManager: MockWindowManager!
    private var mockTabManager: MockTabManager!
    private var mockSummarizationChecker: MockSummarizationChecker!
    private var mockProfile: MockProfile!
    private var mockStore: MockStoreForMiddleware<AppState>!

    override func setUp() async throws {
        try await super.setUp()
        mockProfile = MockProfile()
        mockTabManager = MockTabManager()
        mockWindowManager = MockWindowManager(
            wrappedManager: WindowManagerImplementation(),
            tabManager: mockTabManager
        )
        mockSummarizationChecker = MockSummarizationChecker()
        DependencyHelperMock().bootstrapDependencies(
            injectedWindowManager: mockWindowManager,
            injectedTabManager: mockTabManager
        )
        setupStore()
    }

    override func tearDown() async throws {
        mockProfile = nil
        mockWindowManager = nil
        mockSummarizationChecker = nil
        DependencyHelperMock().reset()
        resetStore()
        try await super.tearDown()
    }

    // TODO(FXIOS-13126): Fix and uncomment this test
//    func test_shakeMotionAction_withFeatureFlagEnabled_dispatchesMiddlewareAction() throws {
//        setupNimbusHostedSummarizerTesting(isEnabled: true)
//        setupWebViewForTabManager()
//        mockSummarizationChecker.overrideResponse = MockSummarizationChecker.success
//
//        let subject = createSubject()
//
//        let action = GeneralBrowserAction(
//            windowUUID: .XCTestDefaultUUID,
//            actionType: GeneralBrowserActionType.shakeMotionEnded
//        )
//        let expectation = XCTestExpectation(description: "General browser action initialize dispatched")
//
//        mockStore.dispatchCalled = {
//            expectation.fulfill()
//        }
//
//        subject.summarizerProvider(AppState(), action)
//
//        wait(for: [expectation], timeout: 1)
//
//        let actionCalled = try XCTUnwrap(mockStore.dispatchedActions.first as? SummarizeAction)
//        let actionType = try XCTUnwrap(actionCalled.actionType as? SummarizeMiddlewareActionType)
//
//        XCTAssertEqual(actionType, SummarizeMiddlewareActionType.configuredSummarizer)
//        XCTAssertEqual(mockStore.dispatchedActions.count, 1)
//        XCTAssertEqual(mockSummarizationChecker.checkCalledCount, 1)
//    }

    func test_shakeMotionAction_failsSummarizerCheck_doesNotDispatchMiddlewareAction() throws {
        setupNimbusHostedSummarizerTesting(isEnabled: true)
        setupWebViewForTabManager()
        mockSummarizationChecker.overrideResponse = MockSummarizationChecker.failure

        let subject = createSubject()

        let action = GeneralBrowserAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: GeneralBrowserActionType.shakeMotionEnded
        )
        let expectation = XCTestExpectation(description: "General browser action initialize dispatched")
        expectation.isInverted = true
        mockStore.dispatchCalled = {
            expectation.fulfill()
        }

        subject.summarizerProvider(AppState(), action)

        wait(for: [expectation], timeout: 1)

        XCTAssertEqual(mockStore.dispatchedActions.count, 0)
        XCTAssertEqual(mockSummarizationChecker.checkCalledCount, 1)
    }

    func test_shakeMotionAction_withoutWebView_doesNotDispatchMiddlewareAction() throws {
        setupNimbusHostedSummarizerTesting(isEnabled: true)
        let subject = createSubject()

        let action = GeneralBrowserAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: GeneralBrowserActionType.shakeMotionEnded
        )
        let expectation = XCTestExpectation(description: "General browser action initialize dispatched")
        expectation.isInverted = true
        mockStore.dispatchCalled = {
            expectation.fulfill()
        }

        subject.summarizerProvider(AppState(), action)

        wait(for: [expectation], timeout: 1)

        XCTAssertEqual(mockStore.dispatchedActions.count, 0)
        XCTAssertEqual(mockSummarizationChecker.checkCalledCount, 0)
    }

    func test_shakeMotionAction_withFeatureFlagDisabled_doesNotDispatchMiddlewareAction() throws {
        setupNimbusHostedSummarizerTesting(isEnabled: false)
        let subject = createSubject()

        let action = GeneralBrowserAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: GeneralBrowserActionType.shakeMotionEnded
        )
        let expectation = XCTestExpectation(description: "General browser action initialize dispatched")
        expectation.isInverted = true
        mockStore.dispatchCalled = {
            expectation.fulfill()
        }

        subject.summarizerProvider(AppState(), action)

        wait(for: [expectation], timeout: 1)

        XCTAssertEqual(mockStore.dispatchedActions.count, 0)
        XCTAssertEqual(mockSummarizationChecker.checkCalledCount, 0)
    }

    // MARK: - Helpers
    private func createSubject() -> SummarizerMiddleware {
        return SummarizerMiddleware(
            logger: MockLogger(),
            windowManager: mockWindowManager,
            summarizationChecker: mockSummarizationChecker
        )
    }

    private func setupWebViewForTabManager() {
        let tab = MockTab(profile: MockProfile(), windowUUID: .XCTestDefaultUUID)
        tab.webView = MockTabWebView(tab: tab)
        mockTabManager.selectedTab = tab
    }

    private func setupNimbusHostedSummarizerTesting(isEnabled: Bool) {
        FxNimbus.shared.features.hostedSummarizerFeature.with { _, _ in
            return HostedSummarizerFeature(enabled: isEnabled)
        }
    }

    // MARK: StoreTestUtility
    func setupAppState() -> AppState {
        return AppState(
            activeScreens: ActiveScreensState(
                screens: [
                    .homepage(
                        HomepageState(
                            windowUUID: .XCTestDefaultUUID
                        )
                    ),
                ]
            )
        )
    }

    func setupStore() {
        mockStore = MockStoreForMiddleware(state: setupAppState())
        StoreTestUtilityHelper.setupStore(with: mockStore)
    }

    // In order to avoid flaky tests, we should reset the store
    // similar to production
    func resetStore() {
        StoreTestUtilityHelper.resetStore()
    }
}
