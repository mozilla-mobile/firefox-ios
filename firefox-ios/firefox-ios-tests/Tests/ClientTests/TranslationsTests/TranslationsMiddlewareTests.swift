// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Redux
import XCTest

@testable import Client

@MainActor
final class TranslationsMiddlewareIntegrationTests: XCTestCase, StoreTestUtility {
    private var mockStore: MockStoreForMiddleware<AppState>!
    private var mockProfile: MockProfile!
    private var mockLogger: MockLogger!
    private var mockWindowManager: MockWindowManager!
    private var mockTabManager: MockTabManager!
    private var mockTranslationsTelemetry: MockTranslationsTelemetry!

    override func setUp() async throws {
        try await super.setUp()
        mockProfile = MockProfile()
        mockLogger = MockLogger()
        mockTabManager = MockTabManager()
        mockWindowManager = MockWindowManager(
            wrappedManager: WindowManagerImplementation(),
            tabManager: mockTabManager
        )
        mockTranslationsTelemetry = MockTranslationsTelemetry()
        DependencyHelperMock().bootstrapDependencies(
            injectedWindowManager: mockWindowManager,
            injectedTabManager: mockTabManager
        )
        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: mockProfile)
        setupStore()
    }

    override func tearDown() async throws {
        mockProfile = nil
        mockLogger = nil
        mockTabManager = nil
        mockWindowManager = nil
        mockTranslationsTelemetry = nil
        DependencyHelperMock().reset()
        resetStore()
        try await super.tearDown()
    }

    // MARK: - urlDidChangeAction tests

    func test_urlDidChangeAction_withoutTranslationConfiguration_doesNotDispatchAction() throws {
        setTranslationsFeatureEnabled(enabled: true)
        let subject = createSubject()
        let action = ToolbarAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: ToolbarActionType.urlDidChange
        )

        subject.translationsProvider(mockStore.state, action)

        XCTAssertEqual(mockStore.dispatchedActions.count, 0)
        XCTAssertNil(mockTranslationsTelemetry.lastTranslationFlowId)
    }

    func test_urlDidChangeAction_withoutFF_doesNotDispatchAction() throws {
        setTranslationsFeatureEnabled(enabled: false)
        let subject = createSubject()
        let action = ToolbarAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: ToolbarActionType.urlDidChange
        )

        subject.translationsProvider(mockStore.state, action)

        XCTAssertEqual(mockStore.dispatchedActions.count, 0)
        XCTAssertNil(mockTranslationsTelemetry.lastTranslationFlowId)
    }

    func test_urlDidChangeAction_withoutWebView_doesDispatchAction() throws {
        setTranslationsFeatureEnabled(enabled: true)
        let subject = createSubject()
        let action = ToolbarAction(
            translationConfiguration: TranslationConfiguration(prefs: mockProfile.prefs),
            windowUUID: .XCTestDefaultUUID,
            actionType: ToolbarActionType.urlDidChange
        )

        subject.translationsProvider(mockStore.state, action)

        XCTAssertEqual(mockStore.dispatchedActions.count, 0)
        XCTAssertNil(mockTranslationsTelemetry.lastTranslationFlowId)
    }

    func test_urlDidChangeAction_withTranslationConfiguration_doesDispatchAction() throws {
        setTranslationsFeatureEnabled(enabled: true)
        let mockTranslationService = MockTranslationsService(
            shouldOfferTranslationResult: .success(true)
        )
        let subject = createSubject(translationsService: mockTranslationService)
        let action = ToolbarAction(
            url: URL(string: "https://www.example.com"),
            translationConfiguration: TranslationConfiguration(prefs: mockProfile.prefs),
            windowUUID: .XCTestDefaultUUID,
            actionType: ToolbarActionType.urlDidChange
        )

        let expectation = XCTestExpectation(description: "expect receivedTranslationLanguage action to be fired")

        mockStore.dispatchCalled = {
            expectation.fulfill()
        }

        subject.translationsProvider(mockStore.state, action)

        wait(for: [expectation], timeout: 1.0)

        let actionCalled = try XCTUnwrap(mockStore.dispatchedActions.first as? ToolbarAction)
        let actionType = try XCTUnwrap(actionCalled.actionType as? ToolbarActionType)

        XCTAssertEqual(actionCalled.translationConfiguration?.state, .inactive)
        XCTAssertEqual(actionType, ToolbarActionType.receivedTranslationLanguage)
        XCTAssertEqual(mockStore.dispatchedActions.count, 1)
        XCTAssertNil(mockTranslationsTelemetry.lastTranslationFlowId)
        XCTAssertEqual(mockTranslationsTelemetry.pageLanguageIdentificationFailedCalledCount, 0)
    }

    func test_urlDidChangeAction_withError_doesNotDispatchActionAndLogsError() throws {
        setTranslationsFeatureEnabled(enabled: true)
        enum TestError: Error { case example }
        let mockTranslationService = MockTranslationsService(
            shouldOfferTranslationResult: .failure(TestError.example)
        )
        let subject = createSubject(translationsService: mockTranslationService)
        let action = ToolbarAction(
            url: URL(string: "https://www.example.com"),
            translationConfiguration: TranslationConfiguration(prefs: mockProfile.prefs),
            windowUUID: .XCTestDefaultUUID,
            actionType: ToolbarActionType.urlDidChange
        )

        let expectation = XCTestExpectation(description: "expect receivedTranslationLanguage action to be fired")
        expectation.isInverted = true

        mockStore.dispatchCalled = {
            expectation.fulfill()
        }

        subject.translationsProvider(mockStore.state, action)

        wait(for: [expectation], timeout: 1.0)

        XCTAssertEqual(mockStore.dispatchedActions.count, 0)
        XCTAssertEqual(mockLogger.savedLevel, .warning)
        XCTAssertEqual(
            mockLogger.savedMessage,
            "Unable to detect language from page to determine if eligible for translations."
        )
        XCTAssertNil(mockTranslationsTelemetry.lastTranslationFlowId)
        XCTAssertEqual(mockTranslationsTelemetry.pageLanguageIdentificationFailedCalledCount, 1)
        XCTAssertNotNil(mockTranslationsTelemetry.lastErrorType)
    }

    func test_urlDidChangeAction_withSamePageLanguage_doesNotDispatchAction() throws {
        setTranslationsFeatureEnabled(enabled: true)
        let mockTranslationService = MockTranslationsService(
            shouldOfferTranslationResult: .success(false)
        )
        let subject = createSubject(translationsService: mockTranslationService)
        let action = ToolbarAction(
            translationConfiguration: TranslationConfiguration(prefs: mockProfile.prefs),
            windowUUID: .XCTestDefaultUUID,
            actionType: ToolbarActionType.urlDidChange
        )

        let expectation = XCTestExpectation(description: "expect receivedTranslationLanguage action to be fired")
        expectation.isInverted = true

        mockStore.dispatchCalled = {
            expectation.fulfill()
        }

        subject.translationsProvider(mockStore.state, action)

        wait(for: [expectation], timeout: 1.0)

        XCTAssertEqual(mockStore.dispatchedActions.count, 0)
    }

    // MARK: - didTapButton tests
    func test_didTapButtonAction_withoutFF_doesNotDispatchAction() throws {
        setTranslationsFeatureEnabled(enabled: false)
        let subject = createSubject()
        let action = ToolbarMiddlewareAction(
            buttonType: .translate,
            gestureType: .tap,
            windowUUID: .XCTestDefaultUUID,
            actionType: ToolbarMiddlewareActionType.didTapButton
        )

        subject.translationsProvider(mockStore.state, action)

        XCTAssertEqual(mockStore.dispatchedActions.count, 0)
        XCTAssertEqual(mockTranslationsTelemetry.translateButtonTappedCalledCount, 0)
    }

    func test_didTapButtonAction_withTranslationConfiguration_dispatchAction() throws {
        setTranslationsFeatureEnabled(enabled: true)
        let subject = createSubject()

        let action = ToolbarMiddlewareAction(
            buttonType: .translate,
            gestureType: .tap,
            windowUUID: .XCTestDefaultUUID,
            actionType: ToolbarMiddlewareActionType.didTapButton
        )

        let expectation = XCTestExpectation(
            description: "expect didStartTranslatingPage, translationCompleted action to be fired"
        )

        expectation.expectedFulfillmentCount = 2

        mockStore.dispatchCalled = {
            expectation.fulfill()
        }
        subject.translationsProvider(setupAppStateWithTranslationConfig(), action)

        wait(for: [expectation], timeout: 1.0)

        XCTAssertEqual(mockStore.dispatchedActions.count, 2)

        let firstActionCalled = try XCTUnwrap(mockStore.dispatchedActions[0] as? ToolbarAction)
        let firstActionType = try XCTUnwrap(firstActionCalled.actionType as? ToolbarActionType)

        let secondActionCalled = try XCTUnwrap(mockStore.dispatchedActions[1] as? ToolbarAction)
        let secondActionType = try XCTUnwrap(secondActionCalled.actionType as? ToolbarActionType)

        XCTAssertEqual(firstActionCalled.translationConfiguration?.state, .loading)
        XCTAssertEqual(firstActionType, ToolbarActionType.didStartTranslatingPage)
        XCTAssertEqual(secondActionCalled.translationConfiguration?.state, .active)
        XCTAssertEqual(secondActionType, ToolbarActionType.translationCompleted)

        XCTAssertEqual(mockTranslationsTelemetry.translateButtonTappedCalledCount, 1)
        XCTAssertEqual(mockTranslationsTelemetry.lastActionType, .willTranslate)
        XCTAssertEqual(mockTranslationsTelemetry.pageLanguageIdentifiedCalledCount, 1)
    }

    func test_didTapButtonAction_withoutTranslationConfiguration_doesNotDispatchAction() throws {
        setTranslationsFeatureEnabled(enabled: true)
        let subject = createSubject()
        let action = ToolbarMiddlewareAction(
            buttonType: .translate,
            gestureType: .tap,
            windowUUID: .XCTestDefaultUUID,
            actionType: ToolbarMiddlewareActionType.didTapButton
        )

        subject.translationsProvider(mockStore.state, action)

        XCTAssertEqual(mockTranslationsTelemetry.translateButtonTappedCalledCount, 0)
        XCTAssertEqual(mockTranslationsTelemetry.pageLanguageIdentifiedCalledCount, 0)
        XCTAssertEqual(mockStore.dispatchedActions.count, 0)
    }

    func test_didTapButtonAction_withError_dispatchToastAction() throws {
        setTranslationsFeatureEnabled(enabled: true)
        enum TestError: Error { case example }
        let mockTranslationsService = MockTranslationsService(
            translateResult: .failure(TestError.example)
        )
        let subject = createSubject(translationsService: mockTranslationsService)
        let action = ToolbarMiddlewareAction(
            buttonType: .translate,
            gestureType: .tap,
            windowUUID: .XCTestDefaultUUID,
            actionType: ToolbarMiddlewareActionType.didTapButton
        )

        let expectation = XCTestExpectation(
            description: "expect didStartTranslatingPage, didReceiveErrorTranslating, showToast action to be fired"
        )
        expectation.expectedFulfillmentCount = 3

        mockStore.dispatchCalled = {
            expectation.fulfill()
        }

        subject.translationsProvider(setupAppStateWithTranslationConfig(), action)

        wait(for: [expectation], timeout: 1.0)

        XCTAssertEqual(mockStore.dispatchedActions.count, 3)

        let firstActionCalled = try XCTUnwrap(mockStore.dispatchedActions[0] as? ToolbarAction)
        let firstActionType = try XCTUnwrap(firstActionCalled.actionType as? ToolbarActionType)

        let secondActionCalled = try XCTUnwrap(mockStore.dispatchedActions[1] as? ToolbarAction)
        let secondActionType = try XCTUnwrap(secondActionCalled.actionType as? ToolbarActionType)

        let thirdActionCalled = try XCTUnwrap(mockStore.dispatchedActions[2] as? GeneralBrowserAction)
        let thirdActionType = try XCTUnwrap(thirdActionCalled.actionType as? GeneralBrowserActionType)

        XCTAssertEqual(firstActionCalled.translationConfiguration?.state, .loading)
        XCTAssertEqual(firstActionType, ToolbarActionType.didStartTranslatingPage)
        XCTAssertEqual(secondActionCalled.translationConfiguration?.state, .inactive)
        XCTAssertEqual(secondActionType, ToolbarActionType.didReceiveErrorTranslating)
        XCTAssertEqual(thirdActionCalled.toastType, .retryTranslatingPage)
        XCTAssertEqual(thirdActionType, GeneralBrowserActionType.showToast)

        XCTAssertEqual(mockTranslationsTelemetry.translateButtonTappedCalledCount, 1)
        XCTAssertEqual(mockTranslationsTelemetry.lastActionType, .willTranslate)
        XCTAssertNotNil(mockTranslationsTelemetry.lastTranslationFlowId)
        XCTAssertEqual(mockTranslationsTelemetry.translationFailedCalledCount, 1)
    }

    func test_didTapButtonAction_withFirstResponseReceivedError_dispatchToastAction() throws {
        setTranslationsFeatureEnabled(enabled: true)
        enum TestError: Error { case example }
        let mockTranslationsService = MockTranslationsService(
            firstResponseReceivedResult: .failure(TestError.example)
        )
        let subject = createSubject(translationsService: mockTranslationsService)
        let action = ToolbarMiddlewareAction(
            buttonType: .translate,
            gestureType: .tap,
            windowUUID: .XCTestDefaultUUID,
            actionType: ToolbarMiddlewareActionType.didTapButton
        )
        let expectation = XCTestExpectation(
            description: "expect didStartTranslatingPage, didReceiveErrorTranslating, showToast action to be fired"
        )
        expectation.expectedFulfillmentCount = 3

        mockStore.dispatchCalled = {
            expectation.fulfill()
        }

        subject.translationsProvider(setupAppStateWithTranslationConfig(), action)

        wait(for: [expectation], timeout: 1.0)

        XCTAssertEqual(mockStore.dispatchedActions.count, 3)

        let firstActionCalled = try XCTUnwrap(mockStore.dispatchedActions[0] as? ToolbarAction)
        let firstActionType = try XCTUnwrap(firstActionCalled.actionType as? ToolbarActionType)

        let secondActionCalled = try XCTUnwrap(mockStore.dispatchedActions[1] as? ToolbarAction)
        let secondActionType = try XCTUnwrap(secondActionCalled.actionType as? ToolbarActionType)

        let thirdActionCalled = try XCTUnwrap(mockStore.dispatchedActions[2] as? GeneralBrowserAction)
        let thirdActionType = try XCTUnwrap(thirdActionCalled.actionType as? GeneralBrowserActionType)

        XCTAssertEqual(firstActionCalled.translationConfiguration?.state, .loading)
        XCTAssertEqual(firstActionType, ToolbarActionType.didStartTranslatingPage)
        XCTAssertEqual(secondActionCalled.translationConfiguration?.state, .inactive)
        XCTAssertEqual(secondActionType, ToolbarActionType.didReceiveErrorTranslating)
        XCTAssertEqual(thirdActionCalled.toastType, .retryTranslatingPage)
        XCTAssertEqual(thirdActionType, GeneralBrowserActionType.showToast)

        XCTAssertEqual(mockTranslationsTelemetry.translateButtonTappedCalledCount, 1)
        XCTAssertEqual(mockTranslationsTelemetry.lastActionType, .willTranslate)
        XCTAssertNotNil(mockTranslationsTelemetry.lastTranslationFlowId)
        XCTAssertEqual(mockTranslationsTelemetry.translationFailedCalledCount, 1)
    }

    func test_didTapButtonAction_withActiveButton_restoresWebPage() throws {
        setTranslationsFeatureEnabled(enabled: true)
        let subject = createSubject()

        let action = ToolbarMiddlewareAction(
            buttonType: .translate,
            gestureType: .tap,
            windowUUID: .XCTestDefaultUUID,
            actionType: ToolbarMiddlewareActionType.didTapButton
        )

        let expectation = XCTestExpectation(
            description: "expect didStartTranslatingPage, translationCompleted action to be fired"
        )

        expectation.expectedFulfillmentCount = 2

        mockStore.dispatchCalled = {
             expectation.fulfill()
        }
        subject.translationsProvider(
            setupAppStateWithTranslationConfig(for: .active),
            action
        )

        wait(for: [expectation], timeout: 1.0)

        XCTAssertEqual(mockStore.dispatchedActions.count, 2)

        let firstActionCalled = try XCTUnwrap(mockStore.dispatchedActions[0] as? ToolbarAction)
        let firstActionType = try XCTUnwrap(firstActionCalled.actionType as? ToolbarActionType)

        let secondActionCalled = try XCTUnwrap(mockStore.dispatchedActions[1] as? GeneralBrowserAction)
        let secondActionType = try XCTUnwrap(secondActionCalled.actionType as? GeneralBrowserActionType)

        XCTAssertEqual(firstActionCalled.translationConfiguration?.state, .inactive)
        XCTAssertEqual(firstActionType, ToolbarActionType.didStartTranslatingPage)
        XCTAssertEqual(secondActionType, GeneralBrowserActionType.reloadWebsite)
        XCTAssertEqual(mockTranslationsTelemetry.lastActionType, .willRestore)
        XCTAssertEqual(mockTranslationsTelemetry.webpageRestoredCalledCount, 1)
    }

    // MARK: - didTapRetryFailedTranslation tests
    func test_didTapRetryFailedTranslationAction_withoutFF_doesNotDispatchAction() throws {
        setTranslationsFeatureEnabled(enabled: false)
        let subject = createSubject()
        let action = ToolbarAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: ToolbarActionType.urlDidChange
        )

        subject.translationsProvider(mockStore.state, action)

        XCTAssertEqual(mockStore.dispatchedActions.count, 0)
    }

    func test_didTapRetryFailedTranslationAction_withSuccess_doesDispatchAction() throws {
        setTranslationsFeatureEnabled(enabled: true)
        let subject = createSubject()
        let action = TranslationsAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: TranslationsActionType.didTapRetryFailedTranslation
        )

        let expectation = XCTestExpectation(
            description: "expect didStartTranslatingPage and translationCompleted action to be fired"
        )
        expectation.expectedFulfillmentCount = 2

        mockStore.dispatchCalled = {
            expectation.fulfill()
        }

        subject.translationsProvider(mockStore.state, action)

        wait(for: [expectation], timeout: 1.0)

        XCTAssertEqual(mockStore.dispatchedActions.count, 2)

        let firstActionCalled = try XCTUnwrap(mockStore.dispatchedActions[0] as? ToolbarAction)
        let firstActionType = try XCTUnwrap(firstActionCalled.actionType as? ToolbarActionType)

        let secondActionCalled = try XCTUnwrap(mockStore.dispatchedActions[1] as? ToolbarAction)
        let secondActionType = try XCTUnwrap(secondActionCalled.actionType as? ToolbarActionType)

        XCTAssertEqual(firstActionCalled.translationConfiguration?.state, .loading)
        XCTAssertEqual(firstActionType, ToolbarActionType.didStartTranslatingPage)

        XCTAssertEqual(secondActionCalled.translationConfiguration?.state, .active)
        XCTAssertEqual(secondActionType, ToolbarActionType.translationCompleted)

        XCTAssertEqual(mockTranslationsTelemetry.pageLanguageIdentifiedCalledCount, 1)
    }

    func test_didTapRetryFailedTranslationAction_withTranslateCurrentPageError_dispatchToastAction() throws {
        setTranslationsFeatureEnabled(enabled: true)
        enum TestError: Error { case example }
        let mockTranslationsService = MockTranslationsService(
            translateResult: .failure(TestError.example)
        )
        let subject = createSubject(translationsService: mockTranslationsService)
        let action = TranslationsAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: TranslationsActionType.didTapRetryFailedTranslation
        )

        let expectation = XCTestExpectation(
            description: "expect didStartTranslatingPage, didReceiveErrorTranslating, showToast action to be fired"
        )
        expectation.expectedFulfillmentCount = 3

        mockStore.dispatchCalled = {
            expectation.fulfill()
        }

        subject.translationsProvider(mockStore.state, action)

        wait(for: [expectation], timeout: 1.0)

        let firstActionCalled = try XCTUnwrap(mockStore.dispatchedActions[0] as? ToolbarAction)
        let firstActionType = try XCTUnwrap(firstActionCalled.actionType as? ToolbarActionType)

        let secondActionCalled = try XCTUnwrap(mockStore.dispatchedActions[1] as? ToolbarAction)
        let secondActionType = try XCTUnwrap(secondActionCalled.actionType as? ToolbarActionType)

        let thirdActionCalled = try XCTUnwrap(mockStore.dispatchedActions[2] as? GeneralBrowserAction)
        let thirdActionType = try XCTUnwrap(thirdActionCalled.actionType as? GeneralBrowserActionType)

        XCTAssertEqual(mockStore.dispatchedActions.count, 3)

        XCTAssertEqual(firstActionCalled.translationConfiguration?.state, .loading)
        XCTAssertEqual(firstActionType, ToolbarActionType.didStartTranslatingPage)
        XCTAssertEqual(secondActionCalled.translationConfiguration?.state, .inactive)
        XCTAssertEqual(secondActionType, ToolbarActionType.didReceiveErrorTranslating)
        XCTAssertEqual(thirdActionCalled.toastType, .retryTranslatingPage)
        XCTAssertEqual(thirdActionType, GeneralBrowserActionType.showToast)

        XCTAssertNotNil(mockTranslationsTelemetry.lastTranslationFlowId)
        XCTAssertEqual(mockTranslationsTelemetry.translationFailedCalledCount, 1)
    }

    func test_didTapRetryFailedTranslationAction_withFirstResponseReceivedError_dispatchToastAction() throws {
        setTranslationsFeatureEnabled(enabled: true)
        enum TestError: Error { case example }
        let mockTranslationsService = MockTranslationsService(
            firstResponseReceivedResult: .failure(TestError.example)
        )
        let subject = createSubject(translationsService: mockTranslationsService)
        let action = TranslationsAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: TranslationsActionType.didTapRetryFailedTranslation
        )

        let expectation = XCTestExpectation(
            description: "expect didStartTranslatingPage, didReceiveErrorTranslating, showToast action to be fired"
        )
        expectation.expectedFulfillmentCount = 3

        mockStore.dispatchCalled = {
            expectation.fulfill()
        }

        subject.translationsProvider(mockStore.state, action)

        wait(for: [expectation], timeout: 1.0)

        XCTAssertEqual(mockStore.dispatchedActions.count, 3)

        let firstActionCalled = try XCTUnwrap(mockStore.dispatchedActions[0] as? ToolbarAction)
        let firstActionType = try XCTUnwrap(firstActionCalled.actionType as? ToolbarActionType)

        let secondActionCalled = try XCTUnwrap(mockStore.dispatchedActions[1] as? ToolbarAction)
        let secondActionType = try XCTUnwrap(secondActionCalled.actionType as? ToolbarActionType)

        let thirdActionCalled = try XCTUnwrap(mockStore.dispatchedActions[2] as? GeneralBrowserAction)
        let thirdActionType = try XCTUnwrap(thirdActionCalled.actionType as? GeneralBrowserActionType)

        XCTAssertEqual(firstActionCalled.translationConfiguration?.state, .loading)
        XCTAssertEqual(firstActionType, ToolbarActionType.didStartTranslatingPage)
        XCTAssertEqual(secondActionCalled.translationConfiguration?.state, .inactive)
        XCTAssertEqual(secondActionType, ToolbarActionType.didReceiveErrorTranslating)
        XCTAssertEqual(thirdActionCalled.toastType, .retryTranslatingPage)
        XCTAssertEqual(thirdActionType, GeneralBrowserActionType.showToast)

        XCTAssertNotNil(mockTranslationsTelemetry.lastTranslationFlowId)
        XCTAssertEqual(mockTranslationsTelemetry.translationFailedCalledCount, 1)
    }

    private func setupAppStateWithTranslationConfig(
        for translationIconState: TranslationConfiguration.IconState = .inactive
    ) -> AppState {
        let initialAction = ToolbarAction(
            url: URL(string: "https://www.example.com"),
            translationConfiguration: TranslationConfiguration(prefs: mockProfile.prefs, state: translationIconState),
            windowUUID: .XCTestDefaultUUID,
            actionType: ToolbarActionType.urlDidChange
        )
        return AppState.reducer(mockStore.state, initialAction)
    }

    // MARK: - Helpers
    private func createSubject(
        translationsService: TranslationsServiceProtocol = MockTranslationsService()
    ) -> TranslationsMiddleware {
        return TranslationsMiddleware(
            profile: mockProfile,
            logger: mockLogger,
            windowManager: mockWindowManager,
            translationsService: translationsService,
            translationsTelemetry: mockTranslationsTelemetry
        )
    }

    private func setupWebViewForTabManager() {
        let tab = MockTab(profile: MockProfile(), windowUUID: .XCTestDefaultUUID)
        tab.webView = MockTabWebView(tab: tab)
        mockTabManager.selectedTab = tab
    }

    private func setTranslationsFeatureEnabled(enabled: Bool) {
        FxNimbus.shared.features.translationsFeature.with { _, _ in
            return TranslationsFeature(enabled: enabled)
        }
    }

    // MARK: StoreTestUtility
    func setupAppState() -> AppState {
        return AppState(
            activeScreens: ActiveScreensState(
                screens: [
                    .browserViewController(
                        BrowserViewControllerState(
                            windowUUID: .XCTestDefaultUUID
                        )
                    ),
                    .toolbar(
                        ToolbarState(
                            windowUUID: .XCTestDefaultUUID
                        )
                    )
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
