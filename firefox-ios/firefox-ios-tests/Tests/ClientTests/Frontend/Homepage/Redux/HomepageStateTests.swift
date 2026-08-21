// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Redux
import XCTest

@testable import Client

final class HomepageStateTests: XCTestCase {
    private var profile: MockProfile!
    private var mockNimbusLayer: MockNimbusFeatureFlagLayer!

    override func setUp() async throws {
        try await super.setUp()
        profile = MockProfile()
        mockNimbusLayer = MockNimbusFeatureFlagLayer()
        let featureFlagProvider = FeatureFlagsProvider(prefs: profile.prefs, backendLayer: mockNimbusLayer)
        let userFeaturePreferences = UserFeaturePreferenceManager(prefs: profile.prefs, backendLayer: mockNimbusLayer)

        await DependencyHelperMock().bootstrapDependencies(
            injectedProfile: profile,
            injectedFeatureFlagProvider: featureFlagProvider,
            injectedUserFeaturePreferences: userFeaturePreferences
        )
    }

    override func tearDown() async throws {
        DependencyHelperMock().reset()
        profile = nil
        mockNimbusLayer = nil
        try await super.tearDown()
    }

    func tests_initialState_returnsExpectedState() {
        let initialState = createSubject()

        XCTAssertEqual(initialState.windowUUID, .XCTestDefaultUUID)

        XCTAssertFalse(initialState.headerState.isPrivate)
        XCTAssertFalse(initialState.trackerBlockerModuleState.shouldShowSection)
    }

    @MainActor
    func test_initializeAction_returnsExpectedState() {
        let initialState = createSubject()
        let reducer = homepageReducer()

        let newState = reducer.legacyReducer(
            initialState,
            HomepageAction(
                windowUUID: .XCTestDefaultUUID,
                actionType: HomepageActionType.initialize
            )
        )

        XCTAssertEqual(newState.windowUUID, .XCTestDefaultUUID)
        XCTAssertFalse(newState.headerState.isPrivate)
    }

    @MainActor
    func test_didSelectedTabChangeToHomepageAction_returnsExpectedState() {
        let initialState = createSubject()
        let reducer = homepageReducer()

        let newState = reducer.legacyReducer(
            initialState,
            GeneralBrowserAction(
                windowUUID: .XCTestDefaultUUID,
                actionType: GeneralBrowserActionType.didSelectedTabChangeToHomepage
            )
        )
        XCTAssertFalse(initialState.telemetryState.shouldTriggerImpression)
        XCTAssertEqual(newState.windowUUID, .XCTestDefaultUUID)
    }

    @MainActor
    func test_handlePrivacyNoticeInitialization_returnsExpectedState() {
        let initialState = createSubject()
        let reducer = homepageReducer()

        let newState = reducer.legacyReducer(
            initialState,
            HomepageAction(
                windowUUID: .XCTestDefaultUUID,
                actionType: HomepageMiddlewareActionType.configuredPrivacyNotice
            )
        )

        XCTAssertTrue(newState.privacyNoticeState.shouldShowPrivacyNotice)
        XCTAssertEqual(newState.windowUUID, .XCTestDefaultUUID)
    }

    @MainActor
    func test_handlePrivacyNoticeCloseButtonTapped_returnsExpectedState() {
        let initialState = createSubject()
        let reducer = homepageReducer()

        let newState = reducer.legacyReducer(
            initialState,
            HomepageAction(
                windowUUID: .XCTestDefaultUUID,
                actionType: HomepageActionType.privacyNoticeCloseButtonTapped
            )
        )

        XCTAssertFalse(newState.privacyNoticeState.shouldShowPrivacyNotice)
        XCTAssertEqual(newState.windowUUID, .XCTestDefaultUUID)
    }

    @MainActor
    func test_trackerBlockerModuleToggleAction_withToggleOn_returnsExpectedState() {
        setFeatureFlag(.homepageTrackerBlockerModule, isEnabled: true)
        let initialState = createSubject()
        let reducer = homepageReducer()

        let newState = reducer.legacyReducer(
            initialState,
            TrackerBlockerModuleAction(
                isEnabled: true,
                windowUUID: .XCTestDefaultUUID,
                actionType: TrackerBlockerModuleActionType.toggleShowSectionSetting
            )
        )

        XCTAssertTrue(newState.trackerBlockerModuleState.shouldShowSection)
    }

    func test_trackerBlockerModuleState_withFeatureDisabledAndPreferenceEnabled_returnsExpectedState() {
        let profile = MockProfile()
        let mockNimbusLayer = MockNimbusFeatureFlagLayer()
        let userPreferences = UserFeaturePreferenceManager(prefs: profile.prefs, backendLayer: mockNimbusLayer)
        userPreferences.setPreferenceFor(.homepageTrackerBlockerModule, to: true)
        let featureFlagsProvider = FeatureFlagsProvider(prefs: profile.prefs, backendLayer: mockNimbusLayer)

        let state = TrackerBlockerModuleState(
            userPreferences: userPreferences,
            featureFlagsProvider: featureFlagsProvider,
            windowUUID: .XCTestDefaultUUID
        )

        XCTAssertFalse(state.shouldShowSection)
    }

    @MainActor
    func test_trackerBlockerModuleToggleAction_withToggleOff_returnsExpectedState() {
        setFeatureFlag(.homepageTrackerBlockerModule, isEnabled: true)
        let initialState = createSubject()
        let reducer = homepageReducer()

        let newState = reducer.legacyReducer(
            initialState,
            TrackerBlockerModuleAction(
                isEnabled: false,
                windowUUID: .XCTestDefaultUUID,
                actionType: TrackerBlockerModuleActionType.toggleShowSectionSetting
            )
        )

        XCTAssertFalse(newState.trackerBlockerModuleState.shouldShowSection)
    }

    // MARK: - Private
    private func createSubject() -> HomepageState {
        return HomepageState(windowUUID: .XCTestDefaultUUID)
    }

    private func homepageReducer() -> Reducer<HomepageState> {
        return HomepageState.reducer
    }

    private func setFeatureFlag(_ flag: FeatureFlagID, isEnabled: Bool) {
        if isEnabled {
            mockNimbusLayer.enabledFlags.insert(flag)
        } else {
            mockNimbusLayer.enabledFlags.remove(flag)
        }
    }
}
