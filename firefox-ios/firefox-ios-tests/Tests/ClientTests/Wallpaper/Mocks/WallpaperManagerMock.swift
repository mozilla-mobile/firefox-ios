// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

@testable import Client

class WallpaperManagerMock: WallpaperManagerInterface {
    var currentWallpaper = Wallpaper(id: "fxDefault",
                                     textColor: .green,
                                     cardColor: .purple,
                                     logoTextColor: .purple)

    var mockAvailableCollections = [WallpaperCollection]()
    var availableCollections: [WallpaperCollection] {
        return mockAvailableCollections
    }

    var canSettingsBeShown = true

    var setCurrentWallpaperCallCount = 0
    var setCurrentWallpaperResult: Result<Void, Error> = .success(())

    func canOnboardingBeShown(using: Profile) -> Bool { return true }

    func onboardingSeen() {}

    func setCurrentWallpaper(
        to wallpaper: Wallpaper,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        setCurrentWallpaperCallCount += 1
        currentWallpaper = wallpaper
        completion(setCurrentWallpaperResult)
    }

    var fetchCallCount = 0
    var fetchResult: Result<Void, Error> = .success(())

    func fetchAssetsFor(_ wallpaper: Wallpaper, completion: @escaping (Result<Void, Error>) -> Void) {
        fetchCallCount += 1
        completion(fetchResult)
    }

    func removeUnusedAssets() {}

    func checkForUpdates() {}

    func migrateLegacyAssets() {}
}
