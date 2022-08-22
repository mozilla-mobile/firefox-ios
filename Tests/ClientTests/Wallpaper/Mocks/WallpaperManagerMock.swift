// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

@testable import Client

class WallpaperManagerMock: WallpaperManagerInterface {

    var currentWallpaper: Wallpaper = Wallpaper(id: "fxDefault", textColour: UIColor.green)

    var mockAvailableCollections = [WallpaperCollection]()
    var availableCollections: [WallpaperCollection] {
        return mockAvailableCollections
    }

    var canOnboardingBeShown: Bool = true

    var setCurrentWallpaperCallCount = 0
    var setCurrentWallpaperResult: Result<Bool, Error> = .success(true)

    func setCurrentWallpaper(
        to wallpaper: Wallpaper,
        completion: @escaping (Result<Bool, Error>) -> Void
    ) {
        setCurrentWallpaperCallCount += 1
        currentWallpaper = wallpaper
        completion(setCurrentWallpaperResult)
    }

    var fetchCallCount = 0
    var fetchResult: Result<Bool, Error> = .success(true)

    func fetch(_ wallpaper: Wallpaper, completion: @escaping (Result<Bool, Error>) -> Void) {
        fetchCallCount += 1
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            completion(self.fetchResult)
        }
    }

    func removeDownloadedAssets() {
    }

    func checkForUpdates() {
    }
}
