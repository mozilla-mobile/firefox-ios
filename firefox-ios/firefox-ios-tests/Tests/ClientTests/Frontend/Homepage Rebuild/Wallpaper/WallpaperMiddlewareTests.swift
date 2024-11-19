// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Redux
import XCTest

@testable import Client

class WallpaperMiddlewareTests: XCTestCase, StoreTestUtility {
    var mockStore: MockStoreForMiddleware<AppState>!
    let wallpaperManager = WallpaperManagerMock()
    var appState: AppState!

    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()

        setupStore()
    }

    override func tearDown() {
        resetStore()
        super.tearDown()
    }

    func test_hompageAction_returnsWallpaperManagerWallpaper() throws {
        let subject = WallpaperMiddleware(wallpaperManager: wallpaperManager)
        let action = HomepageAction(windowUUID: .XCTestDefaultUUID, actionType: HomepageActionType.initialize)

        subject.wallpaperProvider(appState, action)

        let actionCalled = try XCTUnwrap(mockStore.dispatchedActions.first as? WallpaperAction)
        let actionType = try XCTUnwrap(actionCalled.actionType as? WallpaperMiddlewareActionType)

        XCTAssertEqual(mockStore.dispatchedActions.count, 1)
        XCTAssertEqual(actionType, WallpaperMiddlewareActionType.wallpaperDidInitialize)
        XCTAssertEqual(actionCalled.wallpaper.id, "fxDefault")
    }

    func test_wallpaperAction_returnsWallpaperManagerWallpaper() throws {
        let subject = WallpaperMiddleware(wallpaperManager: wallpaperManager)
        let testWallpaper = Wallpaper(id: "test", textColor: .green, cardColor: .yellow, logoTextColor: .orange)
        let action = WallpaperAction(
            wallpaper: testWallpaper,
            windowUUID: .XCTestDefaultUUID,
            actionType: WallpaperActionType.wallpaperSelected
        )

        subject.wallpaperProvider(appState, action)

        let actionCalled = try XCTUnwrap(mockStore.dispatchedActions.first as? WallpaperAction)
        let actionType = try XCTUnwrap(actionCalled.actionType as? WallpaperMiddlewareActionType)

        XCTAssertEqual(mockStore.dispatchedActions.count, 1)
        XCTAssertEqual(actionType, WallpaperMiddlewareActionType.wallpaperDidChange)
        // TODO: FXIOS-10522 will make this test more meaningful by actually configuring the new current wallpaper
        XCTAssertEqual(actionCalled.wallpaper.id, "fxDefault")
    }

    func setupAppState() -> Client.AppState {
        appState = AppState()
        return appState
    }

    func setupStore() {
        mockStore = MockStoreForMiddleware(state: setupAppState())
        StoreTestUtilityHelper.setupStore(with: mockStore)
    }

    func resetStore() {
        StoreTestUtilityHelper.resetStore()
    }
}
