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

    func test_urlDidChangeAction_withoutTranslationConfiguration_doesNotDispatchAction() throws {
        setTranslationsFeatureEnabled(enabled: true)
        let subject = createSubject()
        let action = ToolbarAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: ToolbarActionType.urlDidChange
        )

        subject.translationsProvider(mockStore.state, action)

        XCTAssertEqual(mockStore.dispatchedActions.count, 0)
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
    }

    func test_urlDidChangeAction_withTranslationConfiguration_doesDispatchAction() throws {
        setTranslationsFeatureEnabled(enabled: true)
        let subject = createSubject(shouldOfferTranslationResult: true)
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
    }

    func test_urlDidChangeAction_withError_doesNotDispatchActionAndLogsError() throws {
        setTranslationsFeatureEnabled(enabled: true)
        enum TestError: Error { case example }

        let subject = createSubject(shouldOfferTranslationError: TestError.example)
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
    }

    func test_urlDidChangeAction_withSamePageLanguage_doesNotDispatchAction() throws {
        setTranslationsFeatureEnabled(enabled: true)

        let subject = createSubject(shouldOfferTranslationResult: false)
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

    // MARK: - Helpers
    private func createSubject(
        shouldOfferTranslationResult: Bool = false,
        shouldOfferTranslationError: Error? = nil
    ) -> TranslationsMiddleware {
        let translationsService = MockTranslationsService(
            shouldOfferTranslationResult: shouldOfferTranslationResult,
            shouldOfferTranslationError: shouldOfferTranslationError
        )

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
