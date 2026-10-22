// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@testable import Client

final class WallpaperTests: XCTestCase {
    func testFileNames() {
        let wallpaper = Wallpaper(id: "beachVibes", textColor: nil, cardColor: nil, logoTextColor: nil)

        XCTAssertEqual(wallpaper.fileName(for: .iPhonePortrait), "beachVibes_iPhone_portrait")
        XCTAssertEqual(wallpaper.fileName(for: .iPhoneLandscape), "beachVibes_iPhone_landscape")
        XCTAssertEqual(wallpaper.fileName(for: .iPadPortrait), "beachVibes_iPad_portrait")
        XCTAssertEqual(wallpaper.fileName(for: .iPadLandscape), "beachVibes_iPad_landscape")
    }

    func testThumbnailID() {
        let wallpaper = Wallpaper(id: "beachVibes", textColor: nil, cardColor: nil, logoTextColor: nil)

        XCTAssertEqual(wallpaper.thumbnailID, "beachVibes_thumbnail")
    }

    func testDefaultWallpaper_needsNoResources() {
        XCTAssertFalse(Wallpaper.baseWallpaper.needsToFetchResources)
    }
}
