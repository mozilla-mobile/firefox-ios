// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared

enum WallpaperStorageErrors: Error {
    case fileDoesNotExistError
    case noDataAtFilePath
}

/// Responsible for writing or deleting wallpaper data to/from memory.
struct WallpaperStorageUtility: WallpaperMetadataCodableProtocol {

    private var userDefaults: UserDefaultsInterface
    private var fileManager: FileManager
    private let metadataKey = "metadata"

    // MARK: - Initializer
    init(
        with userDefaults: UserDefaultsInterface = UserDefaults.standard,
        and fileManager: FileManager = FileManager.default
    ) {
        self.userDefaults = userDefaults
        self.fileManager = fileManager
    }

    // MARK: - Storage
    func store(_ metadata: WallpaperMetadata) throws {
        let filePathProvider = WallpaperFilePathProvider()

        if let filePath = filePathProvider.filePath(forKey: metadataKey) {
            let data = try encodeToData(from: metadata)

            if fileManager.fileExists(atPath: filePath.path) {
                try fileManager.removeItem(at: filePath)
            }

            fileManager.createFile(
                atPath: filePath.path,
                contents: data,
                attributes: nil)
        }
    }

    func store(_ wallpaper: Wallpaper) throws {
        let encoded = try JSONEncoder().encode(wallpaper)
        userDefaults.set(encoded, forKey: PrefsKeys.Wallpapers.CurrentWallpaper)
    }

    func store(_ image: UIImage) throws {

    }

    // MARK: - Retrieval

    func fetchMetadata() throws -> WallpaperMetadata? {
        let filePathProvider = WallpaperFilePathProvider()
        guard let filePath = filePathProvider.filePath(forKey: metadataKey) else { return nil }

        if !fileManager.fileExists(atPath: filePath.path) {
            throw WallpaperStorageErrors.fileDoesNotExistError
        }

        if let data = fileManager.contents(atPath: filePath.path) {
            return try decodeMetadata(from: data)

        } else {
            throw WallpaperStorageErrors.noDataAtFilePath
        }
    }

    public func fetchCurrentWallpaper() throws -> Wallpaper? {
        if let data = userDefaults.object(forKey: PrefsKeys.Wallpapers.CurrentWallpaper) as? Data {
            return try JSONDecoder().decode(Wallpaper.self, from: data)
        }

        return nil
    }

    public func fetchImageWith(id: String) throws -> UIImage? {

        return UIImage()
    }

    // MARK: - Deletion
    public func remove() {

    }
}
