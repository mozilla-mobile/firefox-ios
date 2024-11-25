// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Redux
import XCTest

@testable import Client

final class WallpaperStateTests: XCTestCase {
    let image = UIImage.templateImageNamed(ImageIdentifiers.logo)

    func test_initialState_returnsExpectedState() {
        let initialState = createSubject()

        XCTAssertEqual(initialState.windowUUID, .XCTestDefaultUUID)
        XCTAssertNil(initialState.wallpaperConfiguration.landscapeImage)
        XCTAssertNil(initialState.wallpaperConfiguration.portraitImage)
        XCTAssertNil(initialState.wallpaperConfiguration.textColor)
        XCTAssertNil(initialState.wallpaperConfiguration.cardColor)
        XCTAssertNil(initialState.wallpaperConfiguration.logoTextColor)
    }

    func test_wallpaperDidInitialize_returnsExpectedState() {
        let initialState = createSubject()
        let reducer = headerReducer()

        let testWallpaper = WallpaperConfiguration(
            landscapeImage: image,
            portraitImage: image,
            textColor: .black,
            cardColor: .black,
            logoTextColor: .black
        )

        let newState = reducer(
            initialState,
            WallpaperAction(
                wallpaperConfiguration: testWallpaper,
                windowUUID: .XCTestDefaultUUID,
                actionType: WallpaperMiddlewareActionType.wallpaperDidInitialize
            )
        )

        XCTAssertEqual(newState.windowUUID, .XCTestDefaultUUID)
        XCTAssertEqual(newState.wallpaperConfiguration.landscapeImage, image)
        XCTAssertEqual(newState.wallpaperConfiguration.portraitImage, image)
        XCTAssertEqual(newState.wallpaperConfiguration.textColor, .black)
        XCTAssertEqual(newState.wallpaperConfiguration.cardColor, .black)
        XCTAssertEqual(newState.wallpaperConfiguration.logoTextColor, .black)
    }

    func test_wallpaperDidChange_returnsExpectedState() {
        let initialState = createSubject()
        let reducer = headerReducer()

        let testWallpaper = WallpaperConfiguration(
            landscapeImage: image,
            portraitImage: image,
            textColor: .black,
            cardColor: .black,
            logoTextColor: .black
        )

        let newState = reducer(
            initialState,
            WallpaperAction(
                wallpaperConfiguration: testWallpaper,
                windowUUID: .XCTestDefaultUUID,
                actionType: WallpaperMiddlewareActionType.wallpaperDidChange
            )
        )

        XCTAssertEqual(newState.windowUUID, .XCTestDefaultUUID)
        XCTAssertEqual(newState.wallpaperConfiguration.landscapeImage, image)
        XCTAssertEqual(newState.wallpaperConfiguration.portraitImage, image)
        XCTAssertEqual(newState.wallpaperConfiguration.textColor, .black)
        XCTAssertEqual(newState.wallpaperConfiguration.cardColor, .black)
        XCTAssertEqual(newState.wallpaperConfiguration.logoTextColor, .black)
    }

    // MARK: - Private
    private func createSubject() -> WallpaperState {
        return WallpaperState(windowUUID: .XCTestDefaultUUID)
    }

    private func headerReducer() -> Reducer<WallpaperState> {
        return WallpaperState.reducer
    }
}
