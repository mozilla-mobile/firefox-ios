// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import ComponentLibrary
import UIKit
import XCTest

@testable import Client

@MainActor
final class SearchSettingsTableViewControllerTests: XCTestCase, StoreTestUtility {
    private var profile: Profile!
    private var featureFlags: MockNimbusFeatureFlags!
    private var userPreferences: MockUserFeaturePreferences!
    private var mockStore: MockStoreForMiddleware<AppState>!

    override func setUp() async throws {
        try await super.setUp()
        profile = MockProfile()
        featureFlags = MockNimbusFeatureFlags()
        userPreferences = MockUserFeaturePreferences()
        DependencyHelperMock().bootstrapDependencies(
            injectedProfile: profile,
            injectedFeatureFlagProvider: featureFlags,
            injectedUserFeaturePreferences: userPreferences
        )
        setupStore()
    }

    override func tearDown() async throws {
        profile = nil
        featureFlags = nil
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

    func testNumberOfSections_whenGoogleLensFeatureEnabledAndGoogleIsDefault_includesGoogleLensSection() {
        featureFlags.enabledFlags = [.googleLens]
        let subject = createSubject(
            searchEnginesManager: makeSearchEnginesManager(defaultEngineID: OpenSearchEngine.googleEngineID)
        )

        let sectionCount = subject.numberOfSections(in: subject.tableView)

        XCTAssertEqual(sectionCount, 5)
        XCTAssertEqual(subject.tableView(subject.tableView, numberOfRowsInSection: 1), 1)
    }

    func testNumberOfSections_whenGoogleLensFeatureEnabledAndGoogleIsNotDefault_omitsGoogleLensSection() {
        featureFlags.enabledFlags = [.googleLens]
        let subject = createSubject(searchEnginesManager: makeSearchEnginesManager(defaultEngineID: "bing"))

        let sectionCount = subject.numberOfSections(in: subject.tableView)

        XCTAssertEqual(sectionCount, 4)
    }

    private func createSubject(searchEnginesManager: SearchEnginesManager? = nil,
                               file: StaticString = #filePath,
                               line: UInt = #line) -> SearchSettingsTableViewController {
        let searchEnginesManager = searchEnginesManager ?? makeSearchEnginesManager()
        let subject = SearchSettingsTableViewController(profile: profile,
                                                        searchEnginesManager: searchEnginesManager,
                                                        featureFlagsProvider: featureFlags,
                                                        userPreferences: userPreferences,
                                                        windowUUID: .XCTestDefaultUUID)
        trackForMemoryLeaks(subject, file: file, line: line)
        return subject
    }

    private func makeSearchEnginesManager(
        defaultEngineID: String = "bing",
        isCustomEngine: Bool = false
    ) -> SearchEnginesManager {
        let provider = MockSearchEngineProvider()
        provider.mockEngines = [
            makeSearchEngine(engineID: defaultEngineID, isCustomEngine: isCustomEngine),
            makeSearchEngine(engineID: "ddg")
        ]
        return SearchEnginesManager(
            prefs: profile.prefs,
            files: profile.files,
            engineProvider: provider
        )
    }

    private func makeSearchEngine(engineID: String, isCustomEngine: Bool = false) -> OpenSearchEngine {
        return OpenSearchEngine(engineID: engineID,
                                shortName: engineID,
                                telemetrySuffix: nil,
                                image: UIImage(),
                                searchTemplate: "https://example.com/search?q={searchTerms}",
                                suggestTemplate: nil,
                                isCustomEngine: isCustomEngine)
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
