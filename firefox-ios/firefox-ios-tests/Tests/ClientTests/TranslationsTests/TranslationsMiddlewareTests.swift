// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Redux
import XCTest

@testable import Client

final class TranslationsMiddlewareIntegrationTests: XCTestCase, StoreTestUtility {
    var mockStore: MockStoreForMiddleware<AppState>!
    var mockProfile: MockProfile!
    override func setUp() {
        super.setUp()
        mockProfile = MockProfile()
        DependencyHelperMock().bootstrapDependencies()
        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: mockProfile)
        setupStore()
    }

    override func tearDown() {
        mockProfile = nil
        DependencyHelperMock().reset()
        resetStore()
        super.tearDown()
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

    func test_urlDidChangeAction_withTranslationConfiguration_doesDispatchAction() throws {
        setTranslationsFeatureEnabled(enabled: true)
        let subject = createSubject()
        let action = ToolbarAction(
            translationConfiguration: TranslationConfiguration(prefs: mockProfile.prefs),
            windowUUID: .XCTestDefaultUUID,
            actionType: ToolbarActionType.urlDidChange
        )

        subject.translationsProvider(mockStore.state, action)

        let actionCalled = try XCTUnwrap(mockStore.dispatchedActions.first as? ToolbarAction)
        let actionType = try XCTUnwrap(actionCalled.actionType as? ToolbarActionType)

        XCTAssertEqual(action.translationConfiguration?.state, .inactive)
        XCTAssertEqual(actionType, ToolbarActionType.receivedTranslationLanguage)
        XCTAssertEqual(mockStore.dispatchedActions.count, 1)
    }

    // MARK: - Helpers
    private func createSubject() -> TranslationsMiddleware {
        return TranslationsMiddleware()
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
