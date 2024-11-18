// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Redux
import XCTest

@testable import Client

final class WallpaperStateTests: XCTestCase {
    func test_initialState_returnsExpectedState() {
        let initialState = createSubject()

        XCTAssertEqual(initialState.windowUUID, .XCTestDefaultUUID)
        XCTAssertEqual(initialState.wallpaper.id, "fxDefault")
        XCTAssertNil(initialState.wallpaper.textColor)
        XCTAssertNil(initialState.wallpaper.cardColor)
        XCTAssertNil(initialState.wallpaper.logoTextColor)
    }

    func test_wallpaperDidInitialize_returnsExpectedState() {
        let initialState = createSubject()
        let reducer = headerReducer()

        let testWallpaper = Wallpaper(id: "123", textColor: .black, cardColor: .black, logoTextColor: .black)
        let newState = reducer(
            initialState,
            WallpaperAction(
                wallpaper: testWallpaper,
                windowUUID: .XCTestDefaultUUID,
                actionType: WallpaperMiddlewareActionType.wallpaperDidInitialize
            )
        )

        XCTAssertEqual(newState.windowUUID, .XCTestDefaultUUID)
        XCTAssertEqual(newState.wallpaper.id, "123")
        XCTAssertEqual(newState.wallpaper.textColor, .black)
        XCTAssertEqual(newState.wallpaper.cardColor, .black)
        XCTAssertEqual(newState.wallpaper.logoTextColor, .black)
    }

    func test_wallpaperDidChange_returnsExpectedState() {
        let initialState = createSubject()
        let reducer = headerReducer()

        let testWallpaper = Wallpaper(id: "123", textColor: .black, cardColor: .black, logoTextColor: .black)
        let newState = reducer(
            initialState,
            WallpaperAction(
                wallpaper: testWallpaper,
                windowUUID: .XCTestDefaultUUID,
                actionType: WallpaperMiddlewareActionType.wallpaperDidChange
            )
        )

        XCTAssertEqual(newState.windowUUID, .XCTestDefaultUUID)
        XCTAssertEqual(newState.wallpaper.id, "123")
        XCTAssertEqual(newState.wallpaper.textColor, .black)
        XCTAssertEqual(newState.wallpaper.cardColor, .black)
        XCTAssertEqual(newState.wallpaper.logoTextColor, .black)
    }

    // MARK: - Private
    private func createSubject() -> WallpaperState {
        return WallpaperState(windowUUID: .XCTestDefaultUUID)
    }

    private func headerReducer() -> Reducer<WallpaperState> {
        return WallpaperState.reducer
    }
}
