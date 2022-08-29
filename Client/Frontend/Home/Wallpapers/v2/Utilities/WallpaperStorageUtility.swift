// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared

enum WallpaperStorageError: Error {
    case ErrorConvertingData
}

/// Responsible for writing or deleting wallpaper data to/from memory.
struct WallpaperStorageUtility {

    private var userDefaults: UserDefaultsInterface
    private let metadataKey = "metadata"

    // MARK: - Initializer
    init(with userDefaults: UserDefaultsInterface = UserDefaults.standard) {
        self.userDefaults = userDefaults
    }

    func store(_ metadata: WallpaperMetadata) throws {
        let filePathProvider = WallpaperFilePathProvider()

        if let encoded = try? JSONEncoder().encode(metadata),
           let jsonString = String(data: encoded, encoding: .utf8),
           let data = jsonString.data(using: .utf8),
           let filePath = filePathProvider.filePath(forKey: metadataKey) {

            try data.write(to: filePath)
        } else {
            throw WallpaperStorageError.ErrorConvertingData
        }
    }

    func store(_ wallpaper: Wallpaper) {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(wallpaper) {
            userDefaults.set(encoded, forKey: PrefsKeys.Wallpapers.CurrentWallpaper)
        }
    }

    func fetchMetadata() -> WallpaperMetadata? {

        return nil
    }

    public func fetchCurrentWallpaper() -> Wallpaper? {
        if let wallpaper = userDefaults.object(forKey: PrefsKeys.Wallpapers.CurrentWallpaper) as? Data {
            return try? JSONDecoder().decode(Wallpaper.self, from: wallpaper)
        }

        return nil
    }

}
