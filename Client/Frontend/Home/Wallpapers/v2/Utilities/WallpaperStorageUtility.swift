// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared

enum WallpaperStorageErrors: Error {
    case fileDoesNotExistError
    case noDataAtFilePath
    case failedToConvertImage
    case failedSavingFile
    case cannotFindWallpaperDirectory
}

/// Responsible for writing or deleting wallpaper data to/from memory.
struct WallpaperStorageUtility: WallpaperMetadataCodableProtocol {

    private var userDefaults: UserDefaultsInterface
    private var fileManager: FileManagerInterface

    // MARK: - Initializer
    init(
        with userDefaults: UserDefaultsInterface = UserDefaults.standard,
        and fileManager: FileManagerInterface = FileManager.default
    ) {
        self.userDefaults = userDefaults
        self.fileManager = fileManager
    }

    // MARK: - Storage
    func store(_ metadata: WallpaperMetadata) throws {
        let filePathProvider = WallpaperFilePathProvider(with: fileManager)

        if let filePath = filePathProvider.metadataPath() {
            let data = try encodeToData(from: metadata)
            try removeFileIfItExists(at: filePath)

            let successfullyCreated = fileManager.createFile(
                atPath: filePath.path,
                contents: data,
                attributes: nil)

            if !successfullyCreated {
                throw WallpaperStorageErrors.failedSavingFile
            }
        }
    }

    func store(_ wallpaper: Wallpaper) throws {
        let encoded = try JSONEncoder().encode(wallpaper)
        userDefaults.set(encoded, forKey: PrefsKeys.Wallpapers.CurrentWallpaper)
    }

    func store(_ image: UIImage, withName name: String, andKey key: String) throws {
        let filePathProvider = WallpaperFilePathProvider(with: fileManager)

        guard let filePath = filePathProvider.imagePathWith(name: name),
              let pngRepresentation = image.pngData()
        else { throw WallpaperStorageErrors.failedToConvertImage }

        try removeFileIfItExists(at: filePath)
        try pngRepresentation.write(to: filePath, options: .atomic)
    }

    // MARK: - Retrieval

    func fetchMetadata() throws -> WallpaperMetadata? {
        let filePathProvider = WallpaperFilePathProvider(with: fileManager)
        guard let filePath = filePathProvider.metadataPath() else { return nil }

        if !fileManager.fileExists(atPath: filePath.path) {
            throw WallpaperStorageErrors.fileDoesNotExistError
        }

        if let data = fileManager.contents(atPath: filePath.path) {
            return try decodeMetadata(from: data)

        } else {
            throw WallpaperStorageErrors.noDataAtFilePath
        }
    }

    public func fetchCurrentWallpaper() throws -> Wallpaper {
        if let data = userDefaults.object(forKey: PrefsKeys.Wallpapers.CurrentWallpaper) as? Data {
            return try JSONDecoder().decode(Wallpaper.self, from: data)
        }

        return Wallpaper(id: "fxDefault", textColour: nil, cardColour: nil)
    }

    public func fetchImageNamed(_ name: String) throws -> UIImage? {
        let filePathProvider = WallpaperFilePathProvider(with: fileManager)
        guard let filePath = filePathProvider.imagePathWith(name: name),
              let fileData = FileManager.default.contents(atPath: filePath.path),
              let image = UIImage(data: fileData)
        else { return nil }

        return image
    }

    // MARK: - Deletion
    public func removeUnusedLargeWallpaperFiles() throws {
        let filePathProvider = WallpaperFilePathProvider(with: fileManager)
        guard let wallpaperDirectory = filePathProvider.wallpaperDirectoryPath() else {
            throw WallpaperStorageErrors.cannotFindWallpaperDirectory
        }

        let directoryContents = try fileManager.contentsOfDirectory(
            at: wallpaperDirectory,
            includingPropertiesForKeys: nil,
            options: [])

        let directoriesToKeep = try directoriesToKeep()
        for url in directoryContents.filter({ !directoriesToKeep.contains($0.lastPathComponent) }) {
            try removeFileIfItExists(at: url)
        }
    }

    // MARK: - Helper functions
    private func removeFileIfItExists(at url: URL) throws {
        if fileManager.fileExists(atPath: url.path) {
            try fileManager.removeItem(at: url)
        }
    }

    private func directoriesToKeep() throws -> [String] {
        let filePathProvider = WallpaperFilePathProvider(with: fileManager)
        let currentWallpaper = try fetchCurrentWallpaper()
        return [
            currentWallpaper.id,
            filePathProvider.thumbnailsKey,
            filePathProvider.metadataKey
        ]
    }
}
