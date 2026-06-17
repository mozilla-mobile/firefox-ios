// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux
import Shared
import UIKit
import XCTest

@testable import Client

@MainActor
final class WorldCupMatchCardViewTests: XCTestCase, StoreTestUtility {
    private let windowUUID: WindowUUID = .XCTestDefaultUUID
    private var mockStore: MockStoreForMiddleware<AppState>!

    override func setUp() async throws {
        try await super.setUp()
        setupStore()
    }

    override func tearDown() async throws {
        mockStore = nil
        resetStore()
        try await super.tearDown()
    }

    func test_navigateToWallpaperSettings_dispatchesWallpaperSettingsNavigation() throws {
        let subject = createSubject()

        subject.navigateToWallpaperSettings()

        let action = try XCTUnwrap(mockStore.dispatchedActions.first as? NavigationBrowserAction)
        let actionType = try XCTUnwrap(action.actionType as? NavigationBrowserActionType)

        XCTAssertEqual(mockStore.dispatchedActions.count, 1)
        XCTAssertEqual(actionType, .tapOnSettingsSection)
        XCTAssertEqual(action.windowUUID, windowUUID)
        XCTAssertEqual(action.navigationDestination.destination, .settings(.wallpaper))
    }

    func test_shareSchedule_withDefaultEngine_dispatchesShareSheetWithScheduleSearchURL() throws {
        let engine = makeSearchEngine()
        let subject = createSubject(searchEnginesManager: MockSearchEnginesManager(searchEngines: [engine]))

        subject.shareSchedule()

        let action = try XCTUnwrap(mockStore.dispatchedActions.first as? NavigationBrowserAction)
        let actionType = try XCTUnwrap(action.actionType as? NavigationBrowserActionType)

        XCTAssertEqual(mockStore.dispatchedActions.count, 1)
        XCTAssertEqual(actionType, .tapOnShareSheet)
        XCTAssertEqual(action.windowUUID, windowUUID)

        guard case let .shareSheet(configuration) = action.navigationDestination.destination else {
            return XCTFail("Expected a shareSheet navigation destination")
        }

        let query = "\(String.Settings.Homepage.CustomizeFirefoxHome.WorldCup) schedule"
        let expectedURL = try XCTUnwrap(engine.searchURLForQuery(query))
        XCTAssertEqual(configuration.shareType, .site(url: expectedURL))
        XCTAssertEqual(
            configuration.shareMessage,
            ShareMessage(
                message: "\(String.WorldCup.HomepageWidget.FollowTeamCard.Title) 🦊⚽️",
                subtitle: nil
            )
        )
    }

    func test_shareSchedule_withoutDefaultEngine_doesNotDispatch() throws {
        let subject = createSubject(searchEnginesManager: MockSearchEnginesManager(searchEngines: []))

        subject.shareSchedule()

        XCTAssertTrue(mockStore.dispatchedActions.isEmpty)
    }

    private func createSubject(
        searchEnginesManager: SearchEnginesManagerProvider = MockSearchEnginesManager()
    ) -> WorldCupMatchCardView {
        return WorldCupMatchCardView(windowUUID: windowUUID, searchEnginesManager: searchEnginesManager)
    }

    private func makeSearchEngine() -> OpenSearchEngine {
        return OpenSearchEngine(
            engineID: "Firefox",
            shortName: "Firefox",
            telemetrySuffix: nil,
            image: UIImage(),
            searchTemplate: "https://example.com/find?q={searchTerm}",
            suggestTemplate: nil,
            isCustomEngine: false
        )
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
