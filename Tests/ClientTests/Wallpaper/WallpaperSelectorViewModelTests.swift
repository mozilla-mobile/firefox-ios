// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Glean
import XCTest

@testable import Client

class WallpaperSelectorViewModelTests: XCTestCase {

    private var wallpaperManager: WallpaperManagerInterface!

    override func setUp() {
        super.setUp()

        wallpaperManager = WallpaperManager() // needs to be a mock once the manager has real data

        Glean.shared.resetGlean(clearStores: true)
    }

    override func tearDown() {
        super.tearDown()
        wallpaperManager = nil
    }

    func testClickingCell_recordsWallpaperChange() {
        let sut = createSut()
        sut.updateCurrentWallpaper(at: IndexPath(item: 0, section: 0)) { _ in }

        testEventMetricRecordingSuccess(metric: GleanMetrics.Onboarding.selectorWallpaperSelected)
    }

    func createSut() -> WallpaperSelectorViewModel {
        let sut = WallpaperSelectorViewModel(wallpaperManager: wallpaperManager) { }
        trackForMemoryLeaks(sut)
        return sut
    }

}
