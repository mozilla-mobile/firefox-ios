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
    private var mockSummarizerNimbusUtils: MockSummarizerNimbusUtils!
    private var mockSummarizerConfigProvider: MockSummarizerConfigProvider!
    private var mockSummarizerLanguageProvider: MockSummarizerLanguageProvider!
    private let mockURL = URL(string: "https://example.com")!
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
        mockSummarizerNimbusUtils = MockSummarizerNimbusUtils()
        mockSummarizerConfigProvider = MockSummarizerConfigProvider()
        mockSummarizerLanguageProvider = MockSummarizerLanguageProvider()
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
        mockSummarizerNimbusUtils = nil
        DependencyHelperMock().reset()
        resetStore()
        try await super.tearDown()
    }

    func test_shakeMotionAction_withValidConfiguration_dispatchesMiddlewareAction() throws {
        setupWebViewForTabManager()
        mockSummarizerNimbusUtils.isSummarizeFeatureToggledOn = true
        mockSummarizerNimbusUtils.isSummarizeFeatureEnabled = true
        mockSummarizerLanguageProvider.shouldReturnLocale = true
        mockSummarizationChecker.overrideResponse = MockSummarizationChecker.success

        let subject = createSubject()

        let action = GeneralBrowserAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: GeneralBrowserActionType.shakeMotionEnded
        )
        let expectation = XCTestExpectation(description: "General browser action initialize dispatched")

        mockStore.dispatchCalled = {
            expectation.fulfill()
        }

        subject.summarizerProvider(AppState(), action)

        wait(for: [expectation], timeout: 1)

        let actionCalled = try XCTUnwrap(mockStore.dispatchedActions.first as? SummarizeAction)
        let actionType = try XCTUnwrap(actionCalled.actionType as? SummarizeMiddlewareActionType)

        XCTAssertEqual(actionType, SummarizeMiddlewareActionType.configuredSummarizer)
        XCTAssertEqual(mockStore.dispatchedActions.count, 1)
        // the summarizer provider strong retains the middleware as per redux is designed
        // thus trackForMemoryLeaks would fail, the only way is to release the closure by assigning a new one
        subject.summarizerProvider = { _, _ in }
    }

    func test_shakeMotionAction_withoutValidConfigurationAndShakeEnabled_dispatchesToastAction() throws {
        setupWebViewForTabManager()
        mockSummarizerNimbusUtils.isSummarizeFeatureToggledOn = true
        mockSummarizerNimbusUtils.isShakeGestureEnabled = true
        mockSummarizationChecker.overrideResponse = MockSummarizationChecker.failure

        let subject = createSubject()

        let action = GeneralBrowserAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: GeneralBrowserActionType.shakeMotionEnded
        )
        let expectation = XCTestExpectation(description: "General browser action to show toast dispatched")

        mockStore.dispatchCalled = {
            expectation.fulfill()
        }

        subject.summarizerProvider(AppState(), action)

        wait(for: [expectation], timeout: 1)

        let actionCalled = try XCTUnwrap(mockStore.dispatchedActions.first as? GeneralBrowserAction)
        let actionType = try XCTUnwrap(actionCalled.actionType as? GeneralBrowserActionType)

        XCTAssertEqual(actionType, GeneralBrowserActionType.showToast)
        XCTAssertEqual(actionCalled.toastType, .shakeToSummarizeNotAvailable)
        XCTAssertEqual(mockStore.dispatchedActions.count, 1)
        subject.summarizerProvider = { _, _ in }
    }

    func test_shakeMotionAction_withoutValidConfigurationAndShakeDisabled_doesNotDispatchToastAction() throws {
        setupWebViewForTabManager()
        mockSummarizerNimbusUtils.isSummarizeFeatureToggledOn = true
        mockSummarizerNimbusUtils.isShakeGestureEnabled = false

        let subject = createSubject()

        let action = GeneralBrowserAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: GeneralBrowserActionType.shakeMotionEnded
        )
        let expectation = XCTestExpectation(description: "General browser action to show toast dispatched")
        expectation.isInverted = true
        mockStore.dispatchCalled = {
            expectation.fulfill()
        }

        subject.summarizerProvider(AppState(), action)

        wait(for: [expectation], timeout: 1.0)

        XCTAssertEqual(mockStore.dispatchedActions.count, 0)
        subject.summarizerProvider = { _, _ in }
    }

    func test_shakeMotionAction_whenTabIsHomePage_doesNotDispatchToastAction() throws {
        setupWebViewForTabManager()
        mockSummarizerNimbusUtils.isSummarizeFeatureToggledOn = true
        mockSummarizerNimbusUtils.isShakeGestureEnabled = true
        mockSummarizationChecker.overrideResponse = MockSummarizationChecker.failure

        let subject = createSubject()

        let action = GeneralBrowserAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: GeneralBrowserActionType.shakeMotionEnded
        )
        let expectation = XCTestExpectation(description: "General browser action show toast dispatched")
        expectation.isInverted = true
        mockStore.dispatchCalled = {
            expectation.fulfill()
        }

        subject.summarizerProvider(AppState(), action)

        wait(for: [expectation], timeout: 1)

        XCTAssertEqual(mockStore.dispatchedActions.count, 0)
        subject.summarizerProvider = { _, _ in }
    }

    func test_shakeMotionAction_withoutWebView_doesNotDispatchMiddlewareAction() throws {
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
        // the summarizer provider strong retains the middleware as per redux is designed
        // thus trackForMemoryLeaks would fail, the only way is to release the closure by assigning a new one
        subject.summarizerProvider = { _, _ in }
    }

    // MARK: - makeConfiguration
    func test_makeConfiguration_withSummarizerFeatureToggledOff_returnsNil() async {
        let subject = createSubject()
        mockSummarizerNimbusUtils.isSummarizeFeatureToggledOn = false

        let config = await subject.makeConfiguration(from: MockWKWebView(mockURL))

        XCTAssertNil(config)
        XCTAssertEqual(mockSummarizationChecker.checkCalledCount, 0)
    }

    func test_makeConfiguration_withSummarizationCheckFailed_returnsNil() async {
        let subject = createSubject()
        mockSummarizerNimbusUtils.isSummarizeFeatureToggledOn = true
        mockSummarizationChecker.overrideResponse = MockSummarizationChecker.failure

        let config = await subject.makeConfiguration(from: MockWKWebView(mockURL))

        XCTAssertNil(config)
        XCTAssertEqual(mockSummarizationChecker.checkCalledCount, 1)
    }

    func test_makeConfiguration_withLanguageExpansionEnabled_localeNotSupported_returnsNil() async {
        let subject = createSubject()
        mockSummarizerNimbusUtils.isSummarizeFeatureToggledOn = true
        mockSummarizerNimbusUtils.isLanguageExpansionEnabled = true
        mockSummarizerLanguageProvider.shouldReturnLocale = false
        mockSummarizationChecker.overrideResponse = MockSummarizationChecker.success

        let config = await subject.makeConfiguration(from: MockWKWebView(mockURL))

        XCTAssertNil(config)
        XCTAssertEqual(mockSummarizationChecker.checkCalledCount, 1)
        XCTAssertEqual(mockSummarizerNimbusUtils.languageExpansionConfigurationCallCount, 1)
        XCTAssertEqual(mockSummarizerLanguageProvider.getLanguageCallCount, 1)
        XCTAssertEqual(mockSummarizerConfigProvider.getConfigCalledCount, 0)
    }

    func test_makeConfiguration_withLanguageExpansionEnabled_supportedLocale_returnsConfig() async {
        let subject = createSubject()
        mockSummarizerNimbusUtils.isSummarizeFeatureToggledOn = true
        mockSummarizerNimbusUtils.isLanguageExpansionEnabled = true
        mockSummarizerLanguageProvider.shouldReturnLocale = true
        mockSummarizationChecker.overrideResponse = MockSummarizationChecker.success

        let config = await subject.makeConfiguration(from: MockWKWebView(mockURL))

        XCTAssertNotNil(config)
        XCTAssertEqual(mockSummarizationChecker.checkCalledCount, 1)
        XCTAssertEqual(mockSummarizerNimbusUtils.languageExpansionConfigurationCallCount, 1)
        XCTAssertEqual(mockSummarizerLanguageProvider.getLanguageCallCount, 1)
        XCTAssertEqual(mockSummarizerConfigProvider.getConfigCalledCount, 1)
    }

    func test_makeConfiguration_withSummarizeFeatureEnabled_notSupportedLocale_returnsNil() async {
        let subject = createSubject()
        mockSummarizerNimbusUtils.isSummarizeFeatureToggledOn = true
        mockSummarizerNimbusUtils.isSummarizeFeatureEnabled = true
        mockSummarizerNimbusUtils.isLanguageExpansionEnabled = false
        mockSummarizerLanguageProvider.shouldReturnLocale = false
        mockSummarizationChecker.overrideResponse = MockSummarizationChecker.success

        let config = await subject.makeConfiguration(from: MockWKWebView(mockURL))

        XCTAssertNil(config)
        XCTAssertEqual(mockSummarizationChecker.checkCalledCount, 1)
        XCTAssertEqual(mockSummarizerNimbusUtils.languageExpansionConfigurationCallCount, 0)
        XCTAssertEqual(mockSummarizerLanguageProvider.getLanguageCallCount, 1)
        XCTAssertEqual(mockSummarizerConfigProvider.getConfigCalledCount, 0)
    }

    func test_makeConfiguration_withSummarizeFeatureEnabled_supportedLocale_returnsConfig() async {
        let subject = createSubject()
        mockSummarizerNimbusUtils.isSummarizeFeatureToggledOn = true
        mockSummarizerNimbusUtils.isSummarizeFeatureEnabled = true
        mockSummarizerNimbusUtils.isLanguageExpansionEnabled = false
        mockSummarizerLanguageProvider.shouldReturnLocale = true
        mockSummarizationChecker.overrideResponse = MockSummarizationChecker.success

        let config = await subject.makeConfiguration(from: MockWKWebView(mockURL))

        XCTAssertNotNil(config)
        XCTAssertEqual(mockSummarizationChecker.checkCalledCount, 1)
        XCTAssertEqual(mockSummarizerNimbusUtils.languageExpansionConfigurationCallCount, 0)
        XCTAssertEqual(mockSummarizerLanguageProvider.getLanguageCallCount, 1)
        XCTAssertEqual(mockSummarizerConfigProvider.getConfigCalledCount, 1)
    }

    func test_makeConfiguration_withLanguageExpansionDisabledAndSummarizeFeatureDisabled_returnsNil() async {
        let subject = createSubject()
        mockSummarizerNimbusUtils.isSummarizeFeatureToggledOn = true
        mockSummarizerNimbusUtils.isSummarizeFeatureEnabled = false
        mockSummarizerNimbusUtils.isLanguageExpansionEnabled = false
        mockSummarizationChecker.overrideResponse = MockSummarizationChecker.success

        let config = await subject.makeConfiguration(from: MockWKWebView(mockURL))

        XCTAssertNil(config)
        XCTAssertEqual(mockSummarizationChecker.checkCalledCount, 1)
        XCTAssertEqual(mockSummarizerNimbusUtils.languageExpansionConfigurationCallCount, 0)
        XCTAssertEqual(mockSummarizerConfigProvider.getConfigCalledCount, 0)
    }

    // MARK: - Helpers
    private func createSubject() -> SummarizerMiddleware {
        let subject = SummarizerMiddleware(
            logger: MockLogger(),
            windowManager: mockWindowManager,
            profile: mockProfile,
            summarizerNimbusUtility: mockSummarizerNimbusUtils,
            summarizationChecker: mockSummarizationChecker,
            summarizerLanguageProvider: mockSummarizerLanguageProvider,
            summarizerConfigProvider: mockSummarizerConfigProvider
        )
        trackForMemoryLeaks(subject)
        return subject
    }

    private func setupWebViewForTabManager(isHomePage: Bool = false) {
        let tab = MockTab(profile: MockProfile(), windowUUID: .XCTestDefaultUUID, isHomePage: isHomePage)
        tab.webView = MockTabWebView(tab: tab)
        mockTabManager.selectedTab = tab
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
