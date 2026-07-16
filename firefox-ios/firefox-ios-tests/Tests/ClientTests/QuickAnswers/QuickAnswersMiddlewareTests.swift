// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Redux
import Shared
import XCTest

@testable import Client

@MainActor
final class QuickAnswersMiddlewareTests: XCTestCase, StoreTestUtility {
    private var mockStore: MockStoreForMiddleware<AppState>!
    private var mockProfile: MockProfile!
    private var mockFeatureFlags: MockNimbusFeatureFlags!
    private var mockUserPreferences: MockUserFeaturePreferences!

    override func setUp() async throws {
        try await super.setUp()
        mockProfile = MockProfile()
        mockFeatureFlags = MockNimbusFeatureFlags()
        mockUserPreferences = MockUserFeaturePreferences()
        DependencyHelperMock().bootstrapDependencies(
            injectedFeatureFlagProvider: mockFeatureFlags,
            injectedUserFeaturePreferences: mockUserPreferences
        )
        setupStore()
    }

    override func tearDown() async throws {
        resetStore()
        DependencyHelperMock().reset()
        mockUserPreferences = nil
        mockFeatureFlags = nil
        mockProfile = nil
        try await super.tearDown()
    }

    // MARK: - didSettingsChange
    func test_didSettingsChange_dispatchesMiddlewareAction() throws {
        mockFeatureFlags.enabledFlags = [.quickAnswers]
        mockUserPreferences.setPreferenceFor(.quickAnswers, to: true)

        let subject = createSubject()
        let action = QuickAnswersAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: QuickAnswersActionType.didSettingsChange
        )

        subject.quickAnswersProvider.legacyMiddleware(mockStore.state, action)

        XCTAssertEqual(mockStore.dispatchedActions.count, 1)
        let dispatchedAction = try XCTUnwrap(mockStore.dispatchedActions.first as? QuickAnswersMiddlewareAction)
        let dispatchedActionType = try XCTUnwrap(dispatchedAction.actionType as? QuickAnswersMiddlewareActionType)

        XCTAssertEqual(dispatchedActionType, QuickAnswersMiddlewareActionType.didUpdateSettings)
        XCTAssertEqual(dispatchedAction.isQuickAnswersEnabled, true)
    }

    func test_didSettingsChange_whenFeatureFlagDisabled_dispatchesFalse() throws {
        mockFeatureFlags.enabledFlags = []
        mockUserPreferences.setPreferenceFor(.quickAnswers, to: true)

        let subject = createSubject()
        let action = QuickAnswersAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: QuickAnswersActionType.didSettingsChange
        )

        subject.quickAnswersProvider.legacyMiddleware(mockStore.state, action)

        let dispatchedAction = try XCTUnwrap(mockStore.dispatchedActions.first as? QuickAnswersMiddlewareAction)
        XCTAssertEqual(dispatchedAction.isQuickAnswersEnabled, false)
    }

    func test_didSettingsChange_whenUserPreferenceDisabled_dispatchesFalse() throws {
        mockFeatureFlags.enabledFlags = [.quickAnswers]
        mockUserPreferences.setPreferenceFor(.quickAnswers, to: false)

        let subject = createSubject()
        let action = QuickAnswersAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: QuickAnswersActionType.didSettingsChange
        )

        subject.quickAnswersProvider.legacyMiddleware(mockStore.state, action)

        let dispatchedAction = try XCTUnwrap(mockStore.dispatchedActions.first as? QuickAnswersMiddlewareAction)
        XCTAssertEqual(dispatchedAction.isQuickAnswersEnabled, false)
    }

    func test_didSettingsChange_whenBothDisabled_dispatchesFalse() throws {
        mockFeatureFlags.enabledFlags = []
        mockUserPreferences.setPreferenceFor(.quickAnswers, to: false)

        let subject = createSubject()
        let action = QuickAnswersAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: QuickAnswersActionType.didSettingsChange
        )

        subject.quickAnswersProvider.legacyMiddleware(mockStore.state, action)

        let dispatchedAction = try XCTUnwrap(mockStore.dispatchedActions.first as? QuickAnswersMiddlewareAction)
        XCTAssertEqual(dispatchedAction.isQuickAnswersEnabled, false)
    }

    // MARK: - initialize (via HomepageActionType)
    func test_initialize_dispatchesDidInitializeAction() throws {
        mockFeatureFlags.enabledFlags = [.quickAnswers]
        mockUserPreferences.setPreferenceFor(.quickAnswers, to: true)

        let subject = createSubject()
        let action = HomepageAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: HomepageActionType.initialize
        )

        subject.quickAnswersProvider.legacyMiddleware(mockStore.state, action)

        XCTAssertEqual(mockStore.dispatchedActions.count, 1)
        let dispatchedAction = try XCTUnwrap(mockStore.dispatchedActions.first as? QuickAnswersMiddlewareAction)
        let dispatchedActionType = try XCTUnwrap(dispatchedAction.actionType as? QuickAnswersMiddlewareActionType)

        XCTAssertEqual(dispatchedActionType, QuickAnswersMiddlewareActionType.didInitialize)
        XCTAssertEqual(dispatchedAction.isQuickAnswersEnabled, true)
    }

    func test_initialize_whenFeatureFlagDisabled_dispatchesDisabledState() throws {
        mockFeatureFlags.enabledFlags = []
        mockUserPreferences.setPreferenceFor(.quickAnswers, to: true)

        let subject = createSubject()
        let action = HomepageAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: HomepageActionType.initialize
        )

        subject.quickAnswersProvider.legacyMiddleware(mockStore.state, action)

        let dispatchedAction = try XCTUnwrap(mockStore.dispatchedActions.first as? QuickAnswersMiddlewareAction)
        XCTAssertEqual(dispatchedAction.isQuickAnswersEnabled, false)
    }

    func test_initialize_whenUserPreferenceDisabled_dispatchesDisabledState() throws {
        mockFeatureFlags.enabledFlags = [.quickAnswers]
        mockUserPreferences.setPreferenceFor(.quickAnswers, to: false)

        let subject = createSubject()
        let action = HomepageAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: HomepageActionType.initialize
        )

        subject.quickAnswersProvider.legacyMiddleware(mockStore.state, action)

        let dispatchedAction = try XCTUnwrap(mockStore.dispatchedActions.first as? QuickAnswersMiddlewareAction)
        XCTAssertEqual(dispatchedAction.isQuickAnswersEnabled, false)
    }

    // MARK: - StoreTestUtility
    func setupAppState() -> AppState {
        return AppState(
            presentedComponents: PresentedComponentsState(
                components: [
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

    func resetStore() {
        StoreTestUtilityHelper.resetStore()
    }

    // MARK: - Helpers

    private func createSubject() -> QuickAnswersMiddleware {
        let subject = QuickAnswersMiddleware(
            profile: mockProfile,
            featureFlagsProvider: mockFeatureFlags,
            userPreferences: mockUserPreferences
        )
        return subject
    }
}
