// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Redux
import Shared
import XCTest

@testable import Client

@MainActor
final class TranslationSettingsMiddlewareTests: XCTestCase, StoreTestUtility {
    private var mockStore: MockStoreForMiddleware<AppState>!
    private var mockProfile: MockProfile!
    private var mockModelsFetcher: MockTranslationModelsFetcher!

    override func setUp() async throws {
        try await super.setUp()
        mockProfile = MockProfile()
        mockModelsFetcher = MockTranslationModelsFetcher()
        DependencyHelperMock().bootstrapDependencies()
        setupStore()
    }

    override func tearDown() async throws {
        mockProfile = nil
        mockModelsFetcher = nil
        DependencyHelperMock().reset()
        resetStore()
        try await super.tearDown()
    }

    // MARK: - viewDidLoad

    func test_viewDidLoad_dispatchesDidLoadSettings() throws {
        mockModelsFetcher.supportedTargetLanguages = ["en", "fr", "de"]
        mockProfile.prefs.setBool(true, forKey: PrefsKeys.Settings.translationsFeature)
        mockProfile.prefs.setString("en,fr", forKey: PrefsKeys.Settings.translationPreferredLanguages)

        let subject = createSubject()
        let action = TranslationSettingsViewAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: TranslationSettingsViewActionType.viewDidLoad
        )

        let expectation = XCTestExpectation(description: "didLoadSettings action dispatched")
        mockStore.dispatchCalled = { expectation.fulfill() }

        subject.translationSettingsProvider(mockStore.state, action)

        wait(for: [expectation], timeout: 1.0)

        let dispatchedAction = try XCTUnwrap(mockStore.dispatchedActions.first as? TranslationSettingsMiddlewareAction)
        let dispatchedActionType = try XCTUnwrap(dispatchedAction.actionType as? TranslationSettingsMiddlewareActionType)

        XCTAssertEqual(dispatchedActionType, TranslationSettingsMiddlewareActionType.didLoadSettings)
        XCTAssertEqual(dispatchedAction.isTranslationsEnabled, true)
        XCTAssertEqual(dispatchedAction.supportedLanguages, ["en", "fr", "de"])
        XCTAssertEqual(dispatchedAction.preferredLanguages, ["en", "fr"])
        // the translationSettingsProvider strong retains the middleware as per redux is designed
        // thus trackForMemoryLeaks would fail, the only way is to release the closure by assigning a new one
        subject.translationSettingsProvider = { _, _ in }
    }

    func test_viewDidLoad_withTranslationsDisabled_dispatchesDisabledState() throws {
        mockModelsFetcher.supportedTargetLanguages = ["en"]
        mockProfile.prefs.setBool(false, forKey: PrefsKeys.Settings.translationsFeature)
        mockProfile.prefs.setString("en", forKey: PrefsKeys.Settings.translationPreferredLanguages)

        let subject = createSubject()
        let action = TranslationSettingsViewAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: TranslationSettingsViewActionType.viewDidLoad
        )

        let expectation = XCTestExpectation(description: "didLoadSettings dispatched with disabled state")
        mockStore.dispatchCalled = { expectation.fulfill() }

        subject.translationSettingsProvider(mockStore.state, action)

        wait(for: [expectation], timeout: 1.0)

        let dispatchedAction = try XCTUnwrap(mockStore.dispatchedActions.first as? TranslationSettingsMiddlewareAction)
        let dispatchedActionType = try XCTUnwrap(dispatchedAction.actionType as? TranslationSettingsMiddlewareActionType)
        XCTAssertEqual(dispatchedActionType, TranslationSettingsMiddlewareActionType.didLoadSettings)
        XCTAssertEqual(dispatchedAction.isTranslationsEnabled, false)
        XCTAssertEqual(dispatchedAction.preferredLanguages, ["en"])
        // the translationSettingsProvider strong retains the middleware as per redux is designed
        // thus trackForMemoryLeaks would fail, the only way is to release the closure by assigning a new one
        subject.translationSettingsProvider = { _, _ in }
        XCTAssertEqual(dispatchedAction.isTranslationsEnabled, false)
    }

    // MARK: - toggleTranslationsEnabled

    func test_toggleTranslationsEnabled_whenEnabled_disablesAndDispatchesUpdate() throws {
        mockProfile.prefs.setBool(true, forKey: PrefsKeys.Settings.translationsFeature)

        let subject = createSubject()
        let action = TranslationSettingsViewAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: TranslationSettingsViewActionType.toggleTranslationsEnabled
        )

        subject.translationSettingsProvider(mockStore.state, action)

        // Expects ToolbarAction + TranslationSettingsMiddlewareAction
        XCTAssertEqual(mockStore.dispatchedActions.count, 2)

        let toolbarAction = try XCTUnwrap(mockStore.dispatchedActions.first as? ToolbarAction)
        let toolbarActionType = try XCTUnwrap(toolbarAction.actionType as? ToolbarActionType)
        XCTAssertEqual(toolbarActionType, ToolbarActionType.didTranslationSettingsChange)

        let settingsAction = try XCTUnwrap(mockStore.dispatchedActions.last as? TranslationSettingsMiddlewareAction)
        let settingsActionType = try XCTUnwrap(settingsAction.actionType as? TranslationSettingsMiddlewareActionType)

        XCTAssertEqual(settingsActionType, TranslationSettingsMiddlewareActionType.didUpdateSettings)
        XCTAssertEqual(settingsAction.isTranslationsEnabled, false)
        XCTAssertEqual(mockProfile.prefs.boolForKey(PrefsKeys.Settings.translationsFeature), false)
        subject.translationSettingsProvider = { _, _ in }
    }

    func test_toggleTranslationsEnabled_whenDisabled_enablesAndDispatchesUpdate() throws {
        mockProfile.prefs.setBool(false, forKey: PrefsKeys.Settings.translationsFeature)

        let subject = createSubject()
        let action = TranslationSettingsViewAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: TranslationSettingsViewActionType.toggleTranslationsEnabled
        )

        subject.translationSettingsProvider(mockStore.state, action)

        XCTAssertEqual(mockStore.dispatchedActions.count, 2)

        let toolbarAction = try XCTUnwrap(mockStore.dispatchedActions.first as? ToolbarAction)
        let toolbarActionType = try XCTUnwrap(toolbarAction.actionType as? ToolbarActionType)
        XCTAssertEqual(toolbarActionType, ToolbarActionType.didTranslationSettingsChange)

        let settingsAction = try XCTUnwrap(mockStore.dispatchedActions.last as? TranslationSettingsMiddlewareAction)
        XCTAssertEqual(settingsAction.isTranslationsEnabled, true)
        XCTAssertEqual(mockProfile.prefs.boolForKey(PrefsKeys.Settings.translationsFeature), true)
        subject.translationSettingsProvider = { _, _ in }
        let settingsAction = try XCTUnwrap(mockStore.dispatchedActions.last as? TranslationSettingsMiddlewareAction)
        XCTAssertEqual(settingsAction.isTranslationsEnabled, true)
        XCTAssertEqual(mockProfile.prefs.boolForKey(PrefsKeys.Settings.translationsFeature), true)
    }

    // MARK: - Unrelated action

    func test_unrelatedAction_doesNotDispatch() {
        let subject = createSubject()
        let action = GeneralBrowserAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: GeneralBrowserActionType.showToast
        )

        subject.translationSettingsProvider(mockStore.state, action)

        XCTAssertEqual(mockStore.dispatchedActions.count, 0)
        subject.translationSettingsProvider = { _, _ in }
    }

    // MARK: - StoreTestUtility

    func setupAppState() -> AppState {
        return AppState(
            activeScreens: ActiveScreensState(
                screens: [
                    .translationSettings(
                        TranslationSettingsState(windowUUID: .XCTestDefaultUUID)
                    )
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

    private func createSubject() -> TranslationSettingsMiddleware {
        let manager = PreferredTranslationLanguagesManager(prefs: mockProfile.prefs)
        let subject = TranslationSettingsMiddleware(
            profile: mockProfile,
            manager: manager,
            modelsFetcher: mockModelsFetcher
        )
        trackForMemoryLeaks(subject)
        return subject
    }
}
