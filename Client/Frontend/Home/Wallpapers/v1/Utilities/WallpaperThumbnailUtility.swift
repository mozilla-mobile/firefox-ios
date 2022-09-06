// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared

class WallpaperThumbnailUtility {

    // MARK: - Properties
    public var areThumbnailsAvailable: Bool {
        return userDefaults.bool(forKey: prefsKey)
    }

    private var userDefaults: UserDefaultsInterface
    private var networkingModule: WallpaperNetworking
    private let prefsKey = PrefsKeys.Wallpapers.ThumbnailsAvailable

    // MARK: - Initializers
    init(
        with networkingModule: WallpaperNetworking,
        and userDefaults: UserDefaultsInterface = UserDefaults.standard
    ) {
        self.networkingModule = networkingModule
        self.userDefaults = userDefaults
    }

    // MARK: - Public interface
    public func getListOfMissingTumbnails(from collections: [WallpaperCollection]) -> [String: String] {
        var missingThumbnails: [String: String] = [:]

        collections.forEach { collection in
            collection.wallpapers.forEach { wallpaper in
                if wallpaper.type != .defaultWallpaper && wallpaper.thumbnail == nil {
                    missingThumbnails[wallpaper.id] = wallpaper.thumbnailID
                }
            }
        }

        return missingThumbnails
    }

    public func fetchAndVerifyThumbnails(for collections: [WallpaperCollection]) async throws {
        try await fetchMissingThumbnails(from: collections)
        verifyThumbnailsFor(collections)
    }

    public func verifyThumbnailsFor(_ collections: [WallpaperCollection]) {
        userDefaults.set(false, forKey: prefsKey)
        var thumbnailStatus = true
        collections.forEach { collection in
            collection.wallpapers.forEach { wallpaper in
                if wallpaper.type != .defaultWallpaper && wallpaper.thumbnail == nil {
                    thumbnailStatus = thumbnailStatus && false
                }
            }
        }

        userDefaults.set(thumbnailStatus, forKey: prefsKey)
    }

    private func fetchMissingThumbnails(from collections: [WallpaperCollection]) async throws {
        let dataService = WallpaperDataService(with: networkingModule)
        let storageUtility = WallpaperStorageUtility()

        let missingThumbnails = getListOfMissingTumbnails(from: collections)
        if !missingThumbnails.isEmpty {
            for (key, fileName) in missingThumbnails {
                let thumbnail = try await dataService.getImage(named: fileName, withFolderName: key)
                try storageUtility.store(thumbnail, withName: fileName, andKey: key)
            }
        }
    }
}
