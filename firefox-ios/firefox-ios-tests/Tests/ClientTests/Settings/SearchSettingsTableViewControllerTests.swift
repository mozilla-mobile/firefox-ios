// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import ComponentLibrary
import XCTest

@testable import Client

@MainActor
final class SearchSettingsTableViewControllerTests: XCTestCase, StoreTestUtility {
    private var profile: Profile!
    private var userPreferences: MockUserFeaturePreferences!
    private var mockStore: MockStoreForMiddleware<AppState>!

    override func setUp() async throws {
        try await super.setUp()
        profile = MockProfile()
        userPreferences = MockUserFeaturePreferences()
        DependencyHelperMock().bootstrapDependencies(
            injectedProfile: profile,
            injectedUserFeaturePreferences: userPreferences
        )
        setupStore()
    }

    override func tearDown() async throws {
        profile = nil
        userPreferences = nil
        mockStore = nil
        DependencyHelperMock().reset()
        resetStore()
        try await super.tearDown()
    }

    func testDidToggleGoogleLens_savesPreferenceAndDispatchesToolbarAction() throws {
        let subject = createSubject()
        let toggle = ThemedSwitch()
        toggle.isOn = false

        subject.didToggleGoogleLens(toggle)

        let action = try XCTUnwrap(mockStore.dispatchedActions.last as? ToolbarAction)
        let actionType = try XCTUnwrap(action.actionType as? ToolbarActionType)

        XCTAssertEqual(action.windowUUID, .XCTestDefaultUUID)
        XCTAssertEqual(actionType, ToolbarActionType.googleLensSettingDidChange)
        XCTAssertEqual(userPreferences.boolPreferences[.googleLens], false)
    }

    private func createSubject(file: StaticString = #filePath, line: UInt = #line) -> SearchSettingsTableViewController {
        let subject = SearchSettingsTableViewController(profile: profile,
                                                        userPreferences: userPreferences,
                                                        windowUUID: .XCTestDefaultUUID)
        trackForMemoryLeaks(subject, file: file, line: line)
        return subject
    }

    func setupAppState() -> AppState {
        return AppState()
    }

    func setupStore() {
        mockStore = MockStoreForMiddleware(state: setupAppState())
        StoreTestUtilityHelper.setupStore(with: mockStore)
    }

    func resetStore() {
        StoreTestUtilityHelper.resetStore()
    }
}
