// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Redux
import Shared
import TestKit
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

    func test_urlDidChangeAction_withLanguagePickerEnabled_andEligiblePage_doesDispatchAction() throws {
        setTranslationsFeatureEnabled(enabled: true, languagePickerEnabled: true)
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
        mockStore.dispatchCalled = { expectation.fulfill() }

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

    func test_urlDidChangeAction_withNotEligiblePage_dispatchesClearAction() throws {
        setTranslationsFeatureEnabled(enabled: true)
        let mockTranslationService = MockTranslationsService(
            shouldOfferTranslationResult: .success(false)
        )
        let subject = createSubject(translationsService: mockTranslationService)
        let action = ToolbarAction(
            url: URL(string: "https://www.example.com"),
            translationConfiguration: TranslationConfiguration(prefs: mockProfile.prefs),
            windowUUID: .XCTestDefaultUUID,
            actionType: ToolbarActionType.urlDidChange
        )

        let expectation = XCTestExpectation(description: "expect receivedTranslationLanguage clear action to be fired")
        mockStore.dispatchCalled = { expectation.fulfill() }

        subject.translationsProvider(mockStore.state, action)

        wait(for: [expectation], timeout: 1.0)

        let actionCalled = try XCTUnwrap(mockStore.dispatchedActions.first as? ToolbarAction)
        let actionType = try XCTUnwrap(actionCalled.actionType as? ToolbarActionType)

        XCTAssertNil(actionCalled.translationConfiguration)
        XCTAssertEqual(actionType, ToolbarActionType.receivedTranslationLanguage)
        XCTAssertEqual(mockStore.dispatchedActions.count, 1)
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

    func test_didTapButtonAction_withInactiveState_dispatchesShowPickerAction() throws {
        setTranslationsFeatureEnabled(enabled: true, languagePickerEnabled: true)
        let subject = createSubject()

        let action = ToolbarMiddlewareAction(
            buttonType: .translate,
            gestureType: .tap,
            windowUUID: .XCTestDefaultUUID,
            actionType: ToolbarMiddlewareActionType.didTapButton
        )

        let expectation = XCTestExpectation(description: "showTranslationLanguagePicker action dispatched for inactive tap")
        expectation.expectedFulfillmentCount = 1
        mockStore.dispatchCalled = { expectation.fulfill() }

        subject.translationsProvider(setupAppStateWithTranslationConfig(for: .inactive), action)

        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(mockStore.dispatchedActions.count, 1)
        let dispatchedAction = try XCTUnwrap(mockStore.dispatchedActions.first as? GeneralBrowserAction)
        let dispatchedActionType = try XCTUnwrap(dispatchedAction.actionType as? GeneralBrowserActionType)
        XCTAssertEqual(dispatchedActionType, GeneralBrowserActionType.showTranslationLanguagePicker)
    }

    func test_didSelectTargetLanguage_dispatchAction() throws {
        setTranslationsFeatureEnabled(enabled: true)
        mockProfile.prefs.setBool(true, forKey: PrefsKeys.Settings.translationAutoTranslatePromptShown)
        let subject = createSubject()

        let action = TranslationLanguageSelectedAction(
            windowUUID: .XCTestDefaultUUID,
            targetLanguage: "de",
            actionType: TranslationsActionType.didSelectTargetLanguage
        )

        let didStartExpectation = XCTestExpectation(description: "didStartTranslatingPage dispatched")
        let completedExpectation = XCTestExpectation(description: "translationCompleted dispatched")
        mockStore.dispatchCalled = { [weak mockStore] in
            guard let type = mockStore?.dispatchedActions.last?.actionType as? ToolbarActionType else { return }
            switch type {
            case .didStartTranslatingPage: didStartExpectation.fulfill()
            case .translationCompleted: completedExpectation.fulfill()
            default: break
            }
        }
        subject.translationsProvider(mockStore.state, action)

        wait(for: [didStartExpectation, completedExpectation], timeout: 3.0, enforceOrder: true)

        let toolbarActions = mockStore.dispatchedActions.compactMap { $0 as? ToolbarAction }
        let didStart = try XCTUnwrap(toolbarActions.first {
            ($0.actionType as? ToolbarActionType) == .didStartTranslatingPage
        })
        let completed = try XCTUnwrap(toolbarActions.first {
            ($0.actionType as? ToolbarActionType) == .translationCompleted
        })

        XCTAssertEqual(didStart.translationConfiguration?.state, .loading)
        XCTAssertEqual(completed.translationConfiguration?.state, .active)

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

    func test_didSelectTargetLanguage_withTranslationError_dispatchToastAction() throws {
        setTranslationsFeatureEnabled(enabled: true)
        enum TestError: Error { case example }
        let mockTranslationsService = MockTranslationsService(
            translateResult: .failure(TestError.example)
        )
        let subject = createSubject(translationsService: mockTranslationsService)
        let action = TranslationLanguageSelectedAction(
            windowUUID: .XCTestDefaultUUID,
            targetLanguage: "de",
            actionType: TranslationsActionType.didSelectTargetLanguage
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

        XCTAssertEqual(mockTranslationsTelemetry.translateButtonTappedCalledCount, 1)
        XCTAssertEqual(mockTranslationsTelemetry.lastActionType, .willTranslate)
        XCTAssertNotNil(mockTranslationsTelemetry.lastTranslationFlowId)
        XCTAssertEqual(mockTranslationsTelemetry.translationFailedCalledCount, 1)
    }

    func test_didSelectTargetLanguage_withFirstResponseReceivedError_dispatchToastAction() throws {
        setTranslationsFeatureEnabled(enabled: true)
        enum TestError: Error { case example }
        let mockTranslationsService = MockTranslationsService(
            firstResponseReceivedResult: .failure(TestError.example)
        )
        let subject = createSubject(translationsService: mockTranslationsService)
        let action = TranslationLanguageSelectedAction(
            windowUUID: .XCTestDefaultUUID,
            targetLanguage: "de",
            actionType: TranslationsActionType.didSelectTargetLanguage
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

    // MARK: - didTranslationSettingsChange tests

    func test_didTranslationSettingsChange_featureEnabled_eligiblePage_dispatchesReceivedTranslationLanguage() throws {
        setTranslationsFeatureEnabled(enabled: true)
        let mockTranslationService = MockTranslationsService(shouldOfferTranslationResult: .success(true))
        let subject = createSubject(translationsService: mockTranslationService)
        let action = ToolbarAction(
            translationConfiguration: TranslationConfiguration(prefs: mockProfile.prefs),
            windowUUID: .XCTestDefaultUUID,
            actionType: ToolbarActionType.didTranslationSettingsChange
        )

        let expectation = XCTestExpectation(description: "receivedTranslationLanguage dispatched after feature enabled")
        mockStore.dispatchCalled = { expectation.fulfill() }

        subject.translationsProvider(mockStore.state, action)

        wait(for: [expectation], timeout: 1.0)

        let actionCalled = try XCTUnwrap(mockStore.dispatchedActions.first as? ToolbarAction)
        let actionType = try XCTUnwrap(actionCalled.actionType as? ToolbarActionType)
        XCTAssertEqual(actionType, ToolbarActionType.receivedTranslationLanguage)
        XCTAssertEqual(actionCalled.translationConfiguration?.state, .inactive)
        XCTAssertEqual(mockStore.dispatchedActions.count, 1)
    }

    func test_didTranslationSettingsChange_withFeatureDisabled_doesNotDispatchAction() throws {
        setTranslationsFeatureEnabled(enabled: true)
        mockProfile.prefs.setBool(false, forKey: PrefsKeys.Settings.translationsFeature)
        let mockTranslationService = MockTranslationsService(shouldOfferTranslationResult: .success(true))
        let subject = createSubject(translationsService: mockTranslationService)
        let action = ToolbarAction(
            translationConfiguration: TranslationConfiguration(prefs: mockProfile.prefs),
            windowUUID: .XCTestDefaultUUID,
            actionType: ToolbarActionType.didTranslationSettingsChange
        )

        let expectation = XCTestExpectation(description: "no action dispatched when feature disabled")
        expectation.isInverted = true
        mockStore.dispatchCalled = { expectation.fulfill() }

        subject.translationsProvider(mockStore.state, action)

        wait(for: [expectation], timeout: 0.5)
        XCTAssertEqual(mockStore.dispatchedActions.count, 0)
    }

    func test_didTranslationSettingsChange_clearsStoredTargetLanguageForRetry() throws {
        setTranslationsFeatureEnabled(enabled: true)
        mockProfile.prefs.setBool(false, forKey: PrefsKeys.Settings.translationsFeature)
        let subject = createSubject()

        seedTargetLanguage(in: subject, successDispatchCount: 2)

        let toggleAction = ToolbarAction(
            translationConfiguration: TranslationConfiguration(prefs: mockProfile.prefs),
            windowUUID: .XCTestDefaultUUID,
            actionType: ToolbarActionType.didTranslationSettingsChange
        )
        subject.translationsProvider(mockStore.state, toggleAction)

        let retryAction = TranslationsAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: TranslationsActionType.didTapRetryFailedTranslation
        )

        let expectation = XCTestExpectation(description: "no retry dispatch after settings change cleared state")
        expectation.isInverted = true
        mockStore.dispatchCalled = { expectation.fulfill() }

        subject.translationsProvider(mockStore.state, retryAction)

        wait(for: [expectation], timeout: 0.5)
        XCTAssertEqual(mockStore.dispatchedActions.count, 0)
    }

    // MARK: - Auto-translate tests

    func test_urlDidChangeAction_withAutoTranslateEnabled_andPreferredLanguages_translatesAutomatically() throws {
        setTranslationsFeatureEnabled(enabled: true)
        mockProfile.prefs.setBool(true, forKey: PrefsKeys.Settings.translationAutoTranslate)
        mockProfile.prefs.setString("de", forKey: PrefsKeys.Settings.translationPreferredLanguages)
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

        let expectation = XCTestExpectation(
            description: "expect didStartTranslatingPage and translationCompleted to be fired"
        )
        expectation.expectedFulfillmentCount = 2
        mockStore.dispatchCalled = { expectation.fulfill() }

        subject.translationsProvider(mockStore.state, action)

        wait(for: [expectation], timeout: 1.0)

        XCTAssertEqual(mockStore.dispatchedActions.count, 2)

        let firstAction = try XCTUnwrap(mockStore.dispatchedActions[0] as? ToolbarAction)
        let firstActionType = try XCTUnwrap(firstAction.actionType as? ToolbarActionType)

        let secondAction = try XCTUnwrap(mockStore.dispatchedActions[1] as? ToolbarAction)
        let secondActionType = try XCTUnwrap(secondAction.actionType as? ToolbarActionType)

        XCTAssertEqual(firstAction.translationConfiguration?.state, .loading)
        XCTAssertEqual(firstActionType, ToolbarActionType.didStartTranslatingPage)
        XCTAssertEqual(secondAction.translationConfiguration?.state, .active)
        XCTAssertEqual(secondActionType, ToolbarActionType.translationCompleted)
    }

    func test_urlDidChangeAction_withAutoTranslateEnabled_andNoPreferredLanguages_offersManualTranslation() throws {
        setTranslationsFeatureEnabled(enabled: true)
        mockProfile.prefs.setBool(true, forKey: PrefsKeys.Settings.translationAutoTranslate)
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

        let expectation = XCTestExpectation(description: "expect receivedTranslationLanguage to be fired")
        expectation.expectedFulfillmentCount = 1
        mockStore.dispatchCalled = { expectation.fulfill() }

        subject.translationsProvider(mockStore.state, action)

        wait(for: [expectation], timeout: 1.0)

        XCTAssertEqual(mockStore.dispatchedActions.count, 1)

        let dispatchedAction = try XCTUnwrap(mockStore.dispatchedActions.first as? ToolbarAction)
        let dispatchedActionType = try XCTUnwrap(dispatchedAction.actionType as? ToolbarActionType)

        XCTAssertEqual(dispatchedAction.translationConfiguration?.state, .inactive)
        XCTAssertEqual(dispatchedActionType, ToolbarActionType.receivedTranslationLanguage)
    }

    func test_urlDidChangeAction_withAutoTranslateEnabled_afterRestore_skipsAutoTranslateOnce() throws {
        setTranslationsFeatureEnabled(enabled: true)
        mockProfile.prefs.setBool(true, forKey: PrefsKeys.Settings.translationAutoTranslate)
        mockProfile.prefs.setString("de", forKey: PrefsKeys.Settings.translationPreferredLanguages)
        let mockTranslationService = MockTranslationsService(
            shouldOfferTranslationResult: .success(true)
        )
        let subject = createSubject(translationsService: mockTranslationService)

        // Trigger the restore path to populate restoringWindows.
        let restoreAction = ToolbarMiddlewareAction(
            buttonType: .translate,
            gestureType: .tap,
            windowUUID: .XCTestDefaultUUID,
            actionType: ToolbarMiddlewareActionType.didTapButton
        )
        let restoreExpectation = XCTestExpectation(description: "restore dispatches completed")
        restoreExpectation.expectedFulfillmentCount = 2
        mockStore.dispatchCalled = { restoreExpectation.fulfill() }
        subject.translationsProvider(setupAppStateWithTranslationConfig(for: .active), restoreAction)
        wait(for: [restoreExpectation], timeout: 1.0)
        mockStore.dispatchedActions.removeAll()

        // Dispatch urlDidChange — auto-translate is skipped for this cycle.
        let urlAction = ToolbarAction(
            url: URL(string: "https://www.example.com"),
            translationConfiguration: TranslationConfiguration(prefs: mockProfile.prefs),
            windowUUID: .XCTestDefaultUUID,
            actionType: ToolbarActionType.urlDidChange
        )
        let expectation = XCTestExpectation(description: "expect receivedTranslationLanguage to be fired")
        expectation.expectedFulfillmentCount = 1
        mockStore.dispatchCalled = { expectation.fulfill() }

        subject.translationsProvider(mockStore.state, urlAction)

        wait(for: [expectation], timeout: 1.0)

        XCTAssertEqual(mockStore.dispatchedActions.count, 1)

        let dispatchedAction = try XCTUnwrap(mockStore.dispatchedActions.first as? ToolbarAction)
        let dispatchedActionType = try XCTUnwrap(dispatchedAction.actionType as? ToolbarActionType)

        XCTAssertEqual(dispatchedAction.translationConfiguration?.state, .inactive)
        XCTAssertEqual(dispatchedActionType, ToolbarActionType.receivedTranslationLanguage)
    }

    // MARK: - maybeShowAutoTranslatePrompt tests

    func test_translationCompleted_whenPromptNotShownAndAutoTranslateOff_dispatchesShowAutoTranslatePrompt() throws {
        setTranslationsFeatureEnabled(enabled: true)
        let subject = createSubject()

        let action = TranslationLanguageSelectedAction(
            windowUUID: .XCTestDefaultUUID,
            targetLanguage: "de",
            actionType: TranslationsActionType.didSelectTargetLanguage
        )

        let expectation = XCTestExpectation(
            description: "expect didStartTranslatingPage, translationCompleted, showAutoTranslatePrompt to be fired"
        )
        expectation.expectedFulfillmentCount = 3
        mockStore.dispatchCalled = { expectation.fulfill() }
        subject.translationsProvider(mockStore.state, action)

        wait(for: [expectation], timeout: 1.0)

        XCTAssertEqual(mockStore.dispatchedActions.count, 3)

        let thirdAction = try XCTUnwrap(mockStore.dispatchedActions[2] as? TranslationsAction)
        let thirdActionType = try XCTUnwrap(thirdAction.actionType as? TranslationsActionType)

        XCTAssertEqual(thirdActionType, TranslationsActionType.showAutoTranslatePrompt)
        XCTAssertTrue(mockProfile.prefs.boolForKey(PrefsKeys.Settings.translationAutoTranslatePromptShown) ?? false)
    }

    func test_translationCompleted_whenPromptAlreadyShown_doesNotDispatchShowPrompt() throws {
        setTranslationsFeatureEnabled(enabled: true)
        mockProfile.prefs.setBool(true, forKey: PrefsKeys.Settings.translationAutoTranslatePromptShown)
        let subject = createSubject()

        let action = TranslationLanguageSelectedAction(
            windowUUID: .XCTestDefaultUUID,
            targetLanguage: "de",
            actionType: TranslationsActionType.didSelectTargetLanguage
        )

        let expectation = XCTestExpectation(
            description: "expect didStartTranslatingPage and translationCompleted to be fired"
        )
        expectation.expectedFulfillmentCount = 2
        mockStore.dispatchCalled = { expectation.fulfill() }
        subject.translationsProvider(mockStore.state, action)

        wait(for: [expectation], timeout: 1.0)

        XCTAssertEqual(mockStore.dispatchedActions.count, 2)

        let lastActionType = try XCTUnwrap(mockStore.dispatchedActions.last?.actionType as? ToolbarActionType)
        XCTAssertEqual(lastActionType, ToolbarActionType.translationCompleted)
    }

    func test_translationCompleted_whenAutoTranslateAlreadyEnabled_doesNotDispatchShowPrompt() throws {
        setTranslationsFeatureEnabled(enabled: true)
        mockProfile.prefs.setBool(true, forKey: PrefsKeys.Settings.translationAutoTranslate)
        let subject = createSubject()

        let action = TranslationLanguageSelectedAction(
            windowUUID: .XCTestDefaultUUID,
            targetLanguage: "de",
            actionType: TranslationsActionType.didSelectTargetLanguage
        )

        let expectation = XCTestExpectation(
            description: "expect didStartTranslatingPage and translationCompleted to be fired"
        )
        expectation.expectedFulfillmentCount = 2
        mockStore.dispatchCalled = { expectation.fulfill() }
        subject.translationsProvider(mockStore.state, action)

        wait(for: [expectation], timeout: 1.0)

        XCTAssertEqual(mockStore.dispatchedActions.count, 2)

        let lastActionType = try XCTUnwrap(mockStore.dispatchedActions.last?.actionType as? ToolbarActionType)
        XCTAssertEqual(lastActionType, ToolbarActionType.translationCompleted)
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

    func test_didTapRetryFailedTranslationAction_withoutStoredLanguage_doesNotDispatchAction() throws {
        setTranslationsFeatureEnabled(enabled: true)
        let subject = createSubject()
        let action = TranslationsAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: TranslationsActionType.didTapRetryFailedTranslation
        )

        let expectation = XCTestExpectation(description: "no action dispatched without stored language")
        expectation.isInverted = true
        mockStore.dispatchCalled = { expectation.fulfill() }

        subject.translationsProvider(mockStore.state, action)

        wait(for: [expectation], timeout: 0.5)
        XCTAssertEqual(mockStore.dispatchedActions.count, 0)
    }

    func test_didTapRetryFailedTranslationAction_withSuccess_doesDispatchAction() throws {
        setTranslationsFeatureEnabled(enabled: true)
        let subject = createSubject()

        seedTargetLanguage(in: subject, successDispatchCount: 2)

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

        // Seed selectedTargetLanguages (seeding also fails since service errors, hence 3 dispatch calls).
        seedTargetLanguage(in: subject, successDispatchCount: 3)

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

        // Seed selectedTargetLanguages (seeding also fails, hence 3 dispatch calls).
        seedTargetLanguage(in: subject, successDispatchCount: 3)

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

    /// Seeds `selectedTargetLanguages` in the middleware by dispatching a `TranslationLanguageSelectedAction`
    /// and waiting for `successDispatchCount` actions to be dispatched (then clears them).
    private func seedTargetLanguage(
        in subject: TranslationsMiddleware,
        language: String = "de",
        successDispatchCount: Int
    ) {
        let seedAction = TranslationLanguageSelectedAction(
            windowUUID: .XCTestDefaultUUID,
            targetLanguage: language,
            actionType: TranslationsActionType.didSelectTargetLanguage
        )
        let seedExpectation = XCTestExpectation(description: "seed target language")
        seedExpectation.expectedFulfillmentCount = successDispatchCount
        mockStore.dispatchCalled = { seedExpectation.fulfill() }
        subject.translationsProvider(mockStore.state, seedAction)
        wait(for: [seedExpectation], timeout: 1.0)
        mockStore.dispatchedActions.removeAll()
        mockTranslationsTelemetry.reset()
    }

    private func createSubject(
        translationsService: TranslationsServiceProtocol = MockTranslationsService(),
        manager: PreferredTranslationLanguagesManager? = nil,
        localeProvider: LocaleProvider = MockLocaleProvider()
    ) -> TranslationsMiddleware {
        return TranslationsMiddleware(
            profile: mockProfile,
            logger: mockLogger,
            windowManager: mockWindowManager,
            translationsService: translationsService,
            translationsTelemetry: mockTranslationsTelemetry,
            manager: manager,
            localeProvider: localeProvider
        )
    }

    private func setupWebViewForTabManager() {
        let tab = MockTab(profile: MockProfile(), windowUUID: .XCTestDefaultUUID)
        tab.webView = MockTabWebView(tab: tab)
        mockTabManager.selectedTab = tab
    }

    private func setTranslationsFeatureEnabled(enabled: Bool, languagePickerEnabled: Bool = false) {
        FxNimbus.shared.features.translationsFeature.with { _, _ in
            return TranslationsFeature(enabled: enabled, languagePickerEnabled: languagePickerEnabled)
        }
    }

    // MARK: StoreTestUtility
    func setupAppState() -> AppState {
        return AppState(
            presentedComponents: PresentedComponentsState(
                components: [
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
