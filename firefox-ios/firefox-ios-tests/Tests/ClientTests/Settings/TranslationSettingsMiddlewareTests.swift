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

        // viewDidLoad dispatches twice: once synchronously with isTranslationsEnabled,
        // then asynchronously with the full settings (preferredLanguages, supportedLanguages, etc.)
        let expectation = XCTestExpectation(description: "didLoadSettings action dispatched")
        expectation.expectedFulfillmentCount = 2
        mockStore.dispatchCalled = { expectation.fulfill() }

        subject.translationSettingsProvider(mockStore.state, action)

        wait(for: [expectation], timeout: 1.0)

        let dispatchedAction = try XCTUnwrap(mockStore.dispatchedActions.last as? TranslationSettingsMiddlewareAction)
        let dispatchedActionType = try XCTUnwrap(dispatchedAction.actionType as? TranslationSettingsMiddlewareActionType)
        let preferredCodes = dispatchedAction.preferredLanguages?.map { $0.code }

        XCTAssertEqual(dispatchedActionType, TranslationSettingsMiddlewareActionType.didLoadSettings)
        XCTAssertEqual(dispatchedAction.isTranslationsEnabled, true)
        XCTAssertEqual(dispatchedAction.supportedLanguages, ["en", "fr", "de"])
        XCTAssertEqual(preferredCodes, ["en", "fr"])
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
        expectation.expectedFulfillmentCount = 2
        mockStore.dispatchCalled = { expectation.fulfill() }

        subject.translationSettingsProvider(mockStore.state, action)

        wait(for: [expectation], timeout: 1.0)

        let dispatchedAction = try XCTUnwrap(mockStore.dispatchedActions.last as? TranslationSettingsMiddlewareAction)
        let dispatchedActionType = try XCTUnwrap(dispatchedAction.actionType as? TranslationSettingsMiddlewareActionType)
        let preferredCodes = dispatchedAction.preferredLanguages?.map { $0.code }

        XCTAssertEqual(dispatchedActionType, TranslationSettingsMiddlewareActionType.didLoadSettings)
        XCTAssertEqual(dispatchedAction.isTranslationsEnabled, false)
        XCTAssertEqual(preferredCodes, ["en"])
        // the translationSettingsProvider strong retains the middleware as per redux is designed
        // thus trackForMemoryLeaks would fail, the only way is to release the closure by assigning a new one
        subject.translationSettingsProvider = { _, _ in }
    }

    func test_viewDidLoad_deviceLanguage_firstItemHasDeviceLanguageSubtitle() throws {
        mockModelsFetcher.supportedTargetLanguages = ["en", "fr"]
        mockProfile.prefs.setBool(true, forKey: PrefsKeys.Settings.translationsFeature)
        mockProfile.prefs.setString("en,fr", forKey: PrefsKeys.Settings.translationPreferredLanguages)

        let subject = createSubject(localeCode: "en")
        let action = TranslationSettingsViewAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: TranslationSettingsViewActionType.viewDidLoad
        )

        let expectation = XCTestExpectation(description: "didLoadSettings dispatched")
        expectation.expectedFulfillmentCount = 2
        mockStore.dispatchCalled = { expectation.fulfill() }

        subject.translationSettingsProvider(mockStore.state, action)

        wait(for: [expectation], timeout: 1.0)

        let dispatchedAction = try XCTUnwrap(mockStore.dispatchedActions.last as? TranslationSettingsMiddlewareAction)
        let preferredLanguages = try XCTUnwrap(dispatchedAction.preferredLanguages)

        XCTAssertEqual(preferredLanguages[0].code, "en")
        XCTAssertEqual(preferredLanguages[0].subtitleText, .Settings.Translation.PreferredLanguages.DeviceLanguage)
        XCTAssertEqual(preferredLanguages[1].code, "fr")
        subject.translationSettingsProvider = { _, _ in }
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
    }

    // MARK: - saveLanguages

    func test_saveLanguages_persistsLanguagesToPrefsAndDispatchesUpdate() throws {
        let subject = createSubject()
        let action = TranslationSettingsViewAction(
            languages: ["en", "fr"],
            windowUUID: .XCTestDefaultUUID,
            actionType: TranslationSettingsViewActionType.saveLanguages
        )

        subject.translationSettingsProvider(mockStore.state, action)

        let stored = mockProfile.prefs.stringForKey(PrefsKeys.Settings.translationPreferredLanguages)
        XCTAssertEqual(stored, "en,fr")

        let dispatched = try XCTUnwrap(mockStore.dispatchedActions.first as? TranslationSettingsMiddlewareAction)
        let dispatchedType = try XCTUnwrap(dispatched.actionType as? TranslationSettingsMiddlewareActionType)
        let preferredCodes = dispatched.preferredLanguages?.map { $0.code }

        XCTAssertEqual(dispatchedType, TranslationSettingsMiddlewareActionType.didUpdateSettings)
        XCTAssertEqual(preferredCodes, ["en", "fr"])
        subject.translationSettingsProvider = { _, _ in }
    }

    func test_enterEditMode_doesNotDispatchViaMiddleware() {
        let subject = createSubject()
        let action = TranslationSettingsViewAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: TranslationSettingsViewActionType.enterEditMode
        )

        subject.translationSettingsProvider(mockStore.state, action)

        XCTAssertEqual(mockStore.dispatchedActions.count, 0)
        subject.translationSettingsProvider = { _, _ in }
    }

    func test_cancelEditMode_doesNotDispatchViaMiddleware() {
        let subject = createSubject()
        let action = TranslationSettingsViewAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: TranslationSettingsViewActionType.cancelEditMode
        )

        subject.translationSettingsProvider(mockStore.state, action)

        XCTAssertEqual(mockStore.dispatchedActions.count, 0)
        subject.translationSettingsProvider = { _, _ in }
    }

    func test_reorderLanguages_doesNotDispatchViaMiddleware() {
        let subject = createSubject()
        let action = TranslationSettingsViewAction(
            pendingLanguages: makeLanguages(["fr", "en"]),
            windowUUID: .XCTestDefaultUUID,
            actionType: TranslationSettingsViewActionType.reorderLanguages
        )

        subject.translationSettingsProvider(mockStore.state, action)

        XCTAssertEqual(mockStore.dispatchedActions.count, 0)
        subject.translationSettingsProvider = { _, _ in }
    }

    func test_removeLanguage_doesNotDispatchViaMiddleware() {
        let subject = createSubject()
        let action = TranslationSettingsViewAction(
            languageCode: "fr",
            windowUUID: .XCTestDefaultUUID,
            actionType: TranslationSettingsViewActionType.removeLanguage
        )

        subject.translationSettingsProvider(mockStore.state, action)

        XCTAssertEqual(mockStore.dispatchedActions.count, 0)
        subject.translationSettingsProvider = { _, _ in }
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
        return makeAppState()
    }

    private func makeAppState(
        preferredLanguages: [PreferredLanguageDetails] = [],
        pendingLanguages: [PreferredLanguageDetails]? = nil,
        isEditing: Bool = false
    ) -> AppState {
        return AppState(
            presentedComponents: PresentedComponentsState(
                components: [
                    .translationSettings(
                        TranslationSettingsState(
                            windowUUID: .XCTestDefaultUUID,
                            isTranslationsEnabled: true,
                            isEditing: isEditing,
                            pendingLanguages: pendingLanguages,
                            preferredLanguages: preferredLanguages,
                            supportedLanguages: ["en", "fr", "de"]
                        )
                    )
                ]
            )
        )
    }

    private func makeLanguages(_ codes: [String]) -> [PreferredLanguageDetails] {
        return codes.map { PreferredLanguageDetails(code: $0, mainText: $0, subtitleText: nil) }
    }

    func setupStore() {
        mockStore = MockStoreForMiddleware(state: setupAppState())
        StoreTestUtilityHelper.setupStore(with: mockStore)
    }

    func resetStore() {
        StoreTestUtilityHelper.resetStore()
    }

    // MARK: - Helpers

    private func createSubject(localeCode: String = "en") -> TranslationSettingsMiddleware {
        let manager = PreferredTranslationLanguagesManager(prefs: mockProfile.prefs)
        let localeProvider = MockLocaleProvider(current: Locale(identifier: localeCode))
        let subject = TranslationSettingsMiddleware(
            profile: mockProfile,
            manager: manager,
            modelsFetcher: mockModelsFetcher,
            localeProvider: localeProvider
        )
        trackForMemoryLeaks(subject)
        return subject
    }
}
