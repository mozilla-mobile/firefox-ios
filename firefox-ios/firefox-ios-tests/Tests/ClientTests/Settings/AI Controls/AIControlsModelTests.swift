// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Shared

@testable import Client

class AIControlsModelTests: XCTestCase, StoreTestUtility {
    private var mockStore: MockStoreForMiddleware<AppState>!
    var mockPrefs: MockProfilePrefs!

    override func setUp() async throws {
        try await super.setUp()
        setupStore()
        let mockProfile = MockProfile(databasePrefix: "test")
        mockPrefs = MockProfilePrefs(things: [
            PrefsKeys.Summarizer.summarizeContentFeature: true,
            PrefsKeys.Settings.translationsFeature: false,
            PrefsKeys.Settings.aiKillSwitchFeature: true
        ], prefix: "")
        mockProfile.prefs = mockPrefs
        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: mockProfile)
        DependencyHelperMock().bootstrapDependencies(injectedProfile: mockProfile)
    }

    override func tearDown() async throws {
        resetStore()
        try await super.tearDown()
    }

    @MainActor
    func testHeaderLinkInfo() throws {
        let aiControlsModel = createSubject(prefs: mockPrefs)
        XCTAssertEqual(aiControlsModel.headerLinkInfo.label, "Learn more")
        let actualURL = try XCTUnwrap(aiControlsModel.headerLinkInfo.url?.absoluteString)
        let expectedURL = try XCTUnwrap(SupportUtils.URLForTopic("ios-ai-controls", useMobilePath: true)?.absoluteString)
        XCTAssertEqual(actualURL, expectedURL)
    }

    @MainActor
    func testBlockAIEnhancementsLinkInfo() throws {
        let aiControlsModel = createSubject(prefs: mockPrefs)
        XCTAssertEqual(aiControlsModel.blockAIEnhancementsLinkInfo.label, "See what is and isn’t included")
        let actualURL = try XCTUnwrap(aiControlsModel.blockAIEnhancementsLinkInfo.url?.absoluteString)
        let expectedURL = try XCTUnwrap(SupportUtils.URLForTopic("ios-ai-controls", useMobilePath: true)?.absoluteString)
        XCTAssertEqual(actualURL, expectedURL)
    }

    @MainActor
    func testHasVisibleAIFeatures() {
        setupNimbusSentFromFirefoxTesting(isTranslationsEnabled: true, isSummariesEnabled: false)
        let aiControlsModel1 = createSubject(prefs: mockPrefs)
        XCTAssertTrue(aiControlsModel1.hasVisibleAIFeatures)

        setupNimbusSentFromFirefoxTesting(isTranslationsEnabled: false, isSummariesEnabled: true)
        let aiControlsModel2 = createSubject(prefs: mockPrefs)
        XCTAssertTrue(aiControlsModel2.hasVisibleAIFeatures)

        setupNimbusSentFromFirefoxTesting(isTranslationsEnabled: false, isSummariesEnabled: false)
        let aiControlsModel3 = createSubject(prefs: mockPrefs)
        XCTAssertFalse(aiControlsModel3.hasVisibleAIFeatures)
    }

    @MainActor
    func testInitialize() {
        setupNimbusSentFromFirefoxTesting(isTranslationsEnabled: true, isSummariesEnabled: true)
        let aiControlsModel = createSubject(prefs: mockPrefs)
        XCTAssertTrue(aiControlsModel.killSwitchIsOn)
        XCTAssertTrue(aiControlsModel.pageSummariesEnabled)
        XCTAssertFalse(aiControlsModel.translationEnabled)
    }

    @MainActor
    func testInitializeWithTranslationFeatureFlagDisabled() {
        setupNimbusSentFromFirefoxTesting(isTranslationsEnabled: false, isSummariesEnabled: true)
        let aiControlsModel = createSubject(prefs: mockPrefs)
        XCTAssertTrue(aiControlsModel.pageSummariesVisible)
        XCTAssertFalse(aiControlsModel.translationsVisible)
    }

    @MainActor
    func testInitializeWithPageSummariesFeatureFlagDisabled() {
        setupNimbusSentFromFirefoxTesting(isTranslationsEnabled: true, isSummariesEnabled: false)
        let aiControlsModel = createSubject(prefs: mockPrefs)
        XCTAssertFalse(aiControlsModel.pageSummariesVisible)
        XCTAssertTrue(aiControlsModel.translationsVisible)
    }

    @MainActor
    func testToggleKillSwitchOn() throws {
        let expectation = XCTestExpectation(description: "toggleTranslationsEnabled dispatched")
        expectation.expectedFulfillmentCount = 1
        mockStore.dispatchCalled = { expectation.fulfill() }
        mockPrefs = MockProfilePrefs(things: [
            PrefsKeys.Summarizer.summarizeContentFeature: true,
            PrefsKeys.Settings.translationsFeature: false,
            PrefsKeys.Settings.aiKillSwitchFeature: false
        ], prefix: "")
        let aiControlsModel = createSubject(prefs: mockPrefs)
        aiControlsModel.toggleKillSwitch(to: true)

        XCTAssertFalse(aiControlsModel.pageSummariesEnabled)
        XCTAssertFalse(aiControlsModel.translationEnabled)

        if let prefVal = mockPrefs.boolForKey(PrefsKeys.Settings.aiKillSwitchFeature) {
            XCTAssertTrue(prefVal)
        } else {
            XCTFail("No pref value for ai kill switch feature")
        }
    }

    @MainActor
    func testToggleKillSwitchOff() throws {
        let expectation = XCTestExpectation(description: "toggleTranslationsEnabled dispatched")
        expectation.expectedFulfillmentCount = 1
        mockStore.dispatchCalled = { expectation.fulfill() }

        let aiControlsModel = createSubject(prefs: mockPrefs)
        aiControlsModel.toggleKillSwitch(to: false)

        if let prefVal = mockPrefs.boolForKey(PrefsKeys.Settings.aiKillSwitchFeature) {
            XCTAssertFalse(prefVal)
        } else {
            XCTFail("No pref value for ai kill switch feature")
        }
    }

    @MainActor
    func testToggleTranslationsFeature() throws {
        let expectation = XCTestExpectation(description: "toggleTranslationsEnabled dispatched")
        expectation.expectedFulfillmentCount = 1
        mockStore.dispatchCalled = { expectation.fulfill() }
        let aiControlsModel = createSubject(prefs: mockPrefs)
        aiControlsModel.toggleTranslationsFeature(to: true)

        wait(for: [expectation], timeout: 1.0)
        let action = try XCTUnwrap(mockStore.dispatchedActions.last as? TranslationSettingsViewAction)
        XCTAssertTrue(try XCTUnwrap(action.newSettingValue))
    }

    @MainActor
    func testTogglePageSummariesFeatureOn() {
        let aiControlsModel = createSubject(prefs: mockPrefs)
        aiControlsModel.togglePageSummariesFeature(to: true)

        if let prefVal = mockPrefs.boolForKey(PrefsKeys.Summarizer.summarizeContentFeature) {
            XCTAssertTrue(prefVal)
        } else {
            XCTFail("No pref value for translations feature")
        }
    }

    @MainActor
    func testTogglePageSummariesFeatureOff() {
        let aiControlsModel = createSubject(prefs: mockPrefs)
        aiControlsModel.togglePageSummariesFeature(to: false)

        if let prefVal = mockPrefs.boolForKey(PrefsKeys.Summarizer.summarizeContentFeature) {
            XCTAssertFalse(prefVal)
        } else {
            XCTFail("No pref value for translations feature")
        }
    }

    private func setupNimbusSentFromFirefoxTesting(isTranslationsEnabled: Bool, isSummariesEnabled: Bool) {
        FxNimbus.shared.features.translationsFeature.with { _, _ in
            return TranslationsFeature(enabled: isTranslationsEnabled)
        }

        FxNimbus.shared.features.hostedSummarizerFeature.with { _, _ in
            return HostedSummarizerFeature(enabled: isSummariesEnabled)
        }
    }

    @MainActor
    private func createSubject(prefs: Prefs) -> AIControlsModel {
        let subject = AIControlsModel(prefs: prefs, windowUUID: .XCTestDefaultUUID)
        trackForMemoryLeaks(subject)
        return subject
    }

    func setupAppState() -> Client.AppState {
        return AppState(
            presentedComponents: PresentedComponentsState(
                components: [
                    .translationSettings(
                        TranslationSettingsState(
                            windowUUID: .XCTestDefaultUUID,
                            isTranslationsEnabled: true,
                            isEditing: false,
                            pendingLanguages: nil,
                            preferredLanguages: [],
                            supportedLanguages: []
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

    func resetStore() {
        StoreTestUtilityHelper.resetStore()
    }
}
