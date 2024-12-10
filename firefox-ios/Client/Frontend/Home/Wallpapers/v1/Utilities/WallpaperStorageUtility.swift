// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Shared

enum WallpaperStorageError: Error {
    case fileDoesNotExistError
    case noDataAtFilePath
    case failedToConvertImage
    case failedSavingFile
    case cannotFindWallpaperDirectory
    case cannotFindThumbnailDirectory
}

/// Responsible for writing or deleting wallpaper data to/from memory.
struct WallpaperStorageUtility: WallpaperMetadataCodableProtocol {
    private var userDefaults: UserDefaultsInterface
    private var fileManager: FileManagerInterface
    private var logger: Logger

    // MARK: - Initializer
    init(
        with userDefaults: UserDefaultsInterface = UserDefaults.standard,
        and fileManager: FileManagerInterface = FileManager.default,
        logger: Logger = DefaultLogger.shared
    ) {
        self.userDefaults = userDefaults
        self.fileManager = fileManager
        self.logger = logger
    }

    // MARK: - Storage
    func store(_ metadata: WallpaperMetadata) throws {
        let filePathProvider = WallpaperFilePathProvider(with: fileManager)

        if let filePath = filePathProvider.metadataPath() {
            let data = try encodeToData(from: metadata)
            // TODO: [roux] - rename old file to preserve metadata in case of write
            // error. This is more than it first seems.
            try removeFileIfItExists(at: filePath)

            let successfullyCreated = fileManager.createFile(
                atPath: filePath.path,
                contents: data,
                attributes: nil)

            if !successfullyCreated {
                throw WallpaperStorageError.failedSavingFile
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
        else { throw WallpaperStorageError.failedToConvertImage }

        try removeFileIfItExists(at: filePath)
        try pngRepresentation.write(to: filePath, options: .atomic)
    }

    // MARK: - Retrieval

    func fetchMetadata() throws -> WallpaperMetadata? {
        let filePathProvider = WallpaperFilePathProvider(with: fileManager)
        guard let filePath = filePathProvider.metadataPath() else { return nil }

        if !fileManager.fileExists(atPath: filePath.path) {
            throw WallpaperStorageError.fileDoesNotExistError
        }

        if let data = fileManager.contents(atPath: filePath.path) {
            return try decodeMetadata(from: data)
        } else {
            throw WallpaperStorageError.noDataAtFilePath
        }
    }

    public func fetchCurrentWallpaper() -> Wallpaper {
        if let data = userDefaults.object(forKey: PrefsKeys.Wallpapers.CurrentWallpaper) as? Data {
            do {
                return try JSONDecoder().decode(Wallpaper.self, from: data)
            } catch {
                logger.log("WallpaperStorageUtility decoding error: \(error.localizedDescription)",
                           level: .warning,
                           category: .legacyHomepage)
            }
        }

        return Wallpaper.baseWallpaper
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
    public func cleanupUnusedAssets() throws {
        try removeUnusedLargeWallpaperFiles()
        try removeUnusedThumbnails()
    }

    // MARK: - Helper functions
    private func removeUnusedLargeWallpaperFiles() throws {
        let filePathProvider = WallpaperFilePathProvider(with: fileManager)

        guard let wallpaperDirectory = filePathProvider.wallpaperDirectoryPath() else {
            throw WallpaperStorageError.cannotFindWallpaperDirectory
        }

        try removefiles(from: wallpaperDirectory, excluding: try directoriesToKeep())
    }

    private func directoriesToKeep() throws -> [String] {
        let filePathProvider = WallpaperFilePathProvider(with: fileManager)
        let currentWallpaper = fetchCurrentWallpaper()
        return [
            currentWallpaper.id,
            filePathProvider.thumbnailsKey,
            filePathProvider.metadataKey
        ]
    }

    private func removeUnusedThumbnails() throws {
        let filePathProvider = WallpaperFilePathProvider(with: fileManager)

        guard let thumbnailsDirectory = filePathProvider.folderPath(forKey: filePathProvider.thumbnailsKey),
              let metadata = try fetchMetadata()
        else { throw WallpaperStorageError.cannotFindThumbnailDirectory }

        let availableThumbnailIDs = metadata.collections
            .filter { $0.isAvailable }
            .flatMap { $0.wallpapers }
            .map { $0.thumbnailID }

        try removefiles(from: thumbnailsDirectory, excluding: availableThumbnailIDs)
    }

    private func removefiles(from directory: URL, excluding filesToKeep: [String]) throws {
        let directoryContents = try fileManager.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil,
            options: [])

        for url in directoryContents.filter({ !filesToKeep.contains($0.lastPathComponent) }) {
            try removeFileIfItExists(at: url)
        }
    }

    private func removeFileIfItExists(at url: URL) throws {
        if fileManager.fileExists(atPath: url.path) {
            try fileManager.removeItem(at: url)
        }
    }
}
