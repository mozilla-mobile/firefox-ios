// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Redux
import XCTest

@testable import Client

final class HomepageStateTests: XCTestCase {
    override func setUp() async throws {
        try await super.setUp()
        await DependencyHelperMock().bootstrapDependencies()
        setupNimbusHomepageTrackerBlockerModuleTesting(isEnabled: false)
    }

    override func tearDown() async throws {
        DependencyHelperMock().reset()
        try await super.tearDown()
    }

    func tests_initialState_returnsExpectedState() {
        let initialState = createSubject()

        XCTAssertEqual(initialState.windowUUID, .XCTestDefaultUUID)

        XCTAssertFalse(initialState.headerState.isPrivate)
        XCTAssertFalse(initialState.headerState.showiPadSetup)
        XCTAssertFalse(initialState.trackerBlockerModuleState.shouldShowSection)
        XCTAssertFalse(initialState.isZeroSearch)
        XCTAssertFalse(initialState.shouldTriggerImpression)
        XCTAssertEqual(initialState.availableContentHeight, 0)
        XCTAssertEqual(initialState.availableWallpaperHeight, 0)
    }

    @MainActor
    func test_initializeAction_returnsExpectedState() {
        let initialState = createSubject()
        let reducer = homepageReducer()

        let newState = reducer(
            initialState,
            HomepageAction(
                showiPadSetup: true,
                windowUUID: .XCTestDefaultUUID,
                actionType: HomepageActionType.initialize
            )
        )

        XCTAssertEqual(newState.windowUUID, .XCTestDefaultUUID)
        XCTAssertFalse(newState.headerState.isPrivate)
        XCTAssertTrue(newState.headerState.showiPadSetup)
        XCTAssertFalse(newState.isZeroSearch)
        XCTAssertFalse(initialState.shouldTriggerImpression)
        XCTAssertEqual(newState.availableContentHeight, initialState.availableContentHeight)
        XCTAssertEqual(newState.availableWallpaperHeight, initialState.availableWallpaperHeight)
    }

    @MainActor
    func test_embeddedHomepageAction_withTrueZeroSearch_returnsExpectedState() {
        let initialState = createSubject()
        let reducer = homepageReducer()

        let newState = reducer(
            initialState,
            HomepageAction(
                isZeroSearch: true,
                windowUUID: .XCTestDefaultUUID,
                actionType: HomepageActionType.embeddedHomepage
            )
        )

        XCTAssertEqual(newState.windowUUID, .XCTestDefaultUUID)
        XCTAssertTrue(newState.isZeroSearch)
        XCTAssertFalse(initialState.shouldTriggerImpression)
        XCTAssertEqual(newState.availableContentHeight, initialState.availableContentHeight)
        XCTAssertEqual(newState.availableWallpaperHeight, initialState.availableWallpaperHeight)
    }

    @MainActor
    func test_embeddedHomepageAction_withFalseZeroSearch_returnsExpectedState() {
        let initialState = createSubject()
        let reducer = homepageReducer()

        let newState = reducer(
            initialState,
            HomepageAction(
                isZeroSearch: false,
                windowUUID: .XCTestDefaultUUID,
                actionType: HomepageActionType.embeddedHomepage
            )
        )

        XCTAssertEqual(newState.windowUUID, .XCTestDefaultUUID)
        XCTAssertFalse(newState.isZeroSearch)
        XCTAssertFalse(initialState.shouldTriggerImpression)
        XCTAssertEqual(newState.availableContentHeight, initialState.availableContentHeight)
        XCTAssertEqual(newState.availableWallpaperHeight, initialState.availableWallpaperHeight)
    }

    @MainActor
    func test_didSelectedTabChangeToHomepageAction_returnsExpectedState() {
        let initialState = createSubject()
        let reducer = homepageReducer()

        let newState = reducer(
            initialState,
            GeneralBrowserAction(
                windowUUID: .XCTestDefaultUUID,
                actionType: GeneralBrowserActionType.didSelectedTabChangeToHomepage
            )
        )
        XCTAssertFalse(initialState.shouldTriggerImpression)
        XCTAssertEqual(newState.windowUUID, .XCTestDefaultUUID)
        XCTAssertFalse(newState.isZeroSearch)
        XCTAssertTrue(newState.shouldTriggerImpression)
        XCTAssertEqual(newState.availableContentHeight, initialState.availableContentHeight)
        XCTAssertEqual(newState.availableWallpaperHeight, initialState.availableWallpaperHeight)
    }

    @MainActor
    func test_handleAvailableContentHeightChangeAction_returnsExpectedState() {
        let initialState = createSubject()
        let reducer = homepageReducer()

        let newState = reducer(
            initialState,
            HomepageAction(
                availableContentHeight: 500,
                availableWallpaperHeight: 525,
                windowUUID: .XCTestDefaultUUID,
                actionType: HomepageActionType.availableContentHeightDidChange
            )
        )

        XCTAssertEqual(newState.availableContentHeight, 500)
        XCTAssertEqual(newState.availableWallpaperHeight, 525)
        XCTAssertEqual(newState.windowUUID, .XCTestDefaultUUID)
        XCTAssertFalse(newState.shouldTriggerImpression)
        XCTAssertEqual(newState.isZeroSearch, initialState.isZeroSearch)
    }

    @MainActor
    func test_handlePrivacyNoticeInitialization_returnsExpectedState() {
        let initialState = createSubject()
        let reducer = homepageReducer()

        let newState = reducer(
            initialState,
            HomepageAction(
                windowUUID: .XCTestDefaultUUID,
                actionType: HomepageMiddlewareActionType.configuredPrivacyNotice
            )
        )

        XCTAssertTrue(newState.shouldShowPrivacyNotice)
        XCTAssertEqual(newState.windowUUID, .XCTestDefaultUUID)
    }

    @MainActor
    func test_handlePrivacyNoticeCloseButtonTapped_returnsExpectedState() {
        let initialState = createSubject()
        let reducer = homepageReducer()

        let newState = reducer(
            initialState,
            HomepageAction(
                windowUUID: .XCTestDefaultUUID,
                actionType: HomepageActionType.privacyNoticeCloseButtonTapped
            )
        )

        XCTAssertFalse(newState.shouldShowPrivacyNotice)
        XCTAssertEqual(newState.windowUUID, .XCTestDefaultUUID)
    }

    @MainActor
    func test_trackerBlockerModuleToggleAction_withToggleOn_returnsExpectedState() {
        setupNimbusHomepageTrackerBlockerModuleTesting(isEnabled: true)
        let initialState = createSubject()
        let reducer = homepageReducer()

        let newState = reducer(
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
        let userPreferences = MockUserFeaturePreferences()
        userPreferences.setPreferenceFor(.homepageTrackerBlockerModule, to: true)
        let featureFlagsProvider = MockNimbusFeatureFlags()

        let state = TrackerBlockerModuleState(
            userPreferences: userPreferences,
            featureFlagsProvider: featureFlagsProvider,
            windowUUID: .XCTestDefaultUUID
        )

        XCTAssertFalse(state.shouldShowSection)
    }

    @MainActor
    func test_trackerBlockerModuleToggleAction_withToggleOff_returnsExpectedState() {
        setupNimbusHomepageTrackerBlockerModuleTesting(isEnabled: true)
        let initialState = createSubject()
        let reducer = homepageReducer()

        let newState = reducer(
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

    private func setupNimbusHomepageTrackerBlockerModuleTesting(isEnabled: Bool) {
        FxNimbus.shared.features.homepageTrackerBlockerModuleFeature.with { _, _ in
            return HomepageTrackerBlockerModuleFeature(enabled: isEnabled)
        }
    }
}
