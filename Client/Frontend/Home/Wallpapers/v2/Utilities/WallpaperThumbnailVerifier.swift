// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared

class WallpaperThumbnailVerifier {

    // MARK: - Properties
    public var thumbnailsAvailable: Bool {
        return userDefaults.bool(forKey: prefsKey)
    }

    private var userDefaults: UserDefaultsInterface
    private let prefsKey = PrefsKeys.Wallpapers.ThumbnailsAvailable

    // MARK: - Initializers
    init(with userDefaults: UserDefaultsInterface = UserDefaults.standard) {
        self.userDefaults = userDefaults
    }

    // MARK: - Public interface
    public func verifyThumbnailsFor(_ collections: [WallpaperCollection]) {
        userDefaults.set(false, forKey: prefsKey)
        var thumbnailStatus = true
        collections.forEach { collection in
            collection.wallpapers.forEach { wallpaper in
                if wallpaper.thumbnail == nil {
                    thumbnailStatus = thumbnailStatus && false
                }
            }
        }

        userDefaults.set(thumbnailStatus, forKey: prefsKey)
    }
}

