// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common

/// Responsible for providing the required file paths on the disk.
struct WallpaperFilePathProvider {
    private var fileManager: FileManagerInterface
    private var logger: Logger
    public let metadataKey = "metadata"
    public let thumbnailsKey = "thumbnails"

    init(with fileManager: FileManagerInterface,
         logger: Logger = DefaultLogger.shared) {
        self.fileManager = fileManager
        self.logger = logger
    }

    // MARK: - Public interface
    /// Given a key, creates a URL pointing to the
    /// `.../wallpaper/key-as-folder/key-as-filePath` of the application's document directory.
    ///
    /// - Parameter key: The key to be used as the final path for the file.
    /// - Returns: A URL containing the correct path for the key.
    public func metadataPath() -> URL? {
        guard let keyDirectoryPath = folderPath(forKey: metadataKey) else {
            logger.log("WallpaperFilePathProtocol - error fetching keyed directory path for application",
                       level: .debug,
                       category: .legacyHomepage)
            return nil
        }

        return keyDirectoryPath.appendingPathComponent(metadataKey)
    }

    /// Given a key, creates a URL pointing to the
    /// `.../wallpaper/base-file-name-as-folderPath/name-as-filePath`
    /// of the application's document directory.
    ///
    /// - Parameters:
    ///   - name: The name to be used as the final path for the file.
    /// - Returns: A URL containing the correct path for the key.
    public func imagePathWith(name: String) -> URL? {
        let key = getFolderName(from: name)
        guard let keyDirectoryPath = folderPath(forKey: key) else {
            logger.log("WallpaperFilePathProvider - error fetching keyed directory path for application",
                       level: .debug,
                       category: .legacyHomepage)
            return nil
        }

        return keyDirectoryPath.appendingPathComponent(name)
    }

    /// Given a key, creates a URL pointing to the `wallpaper/key-as-folder` folder
    /// of the application's document directory.
    ///
    /// - Parameter key: The key to be used as the file's containing folder
    /// - Parameter fileManager: The file manager to use to persist and retrieve the wallpaper.
    /// - Returns: A URL containing the correct path for the key.
    public func folderPath(forKey key: String) -> URL? {
        guard let wallpaperDirectoryPath = wallpaperDirectoryPath() else { return nil }

        let keyDirectoryPath = wallpaperDirectoryPath.appendingPathComponent(key)
        createFolderAt(path: keyDirectoryPath)

        return keyDirectoryPath
    }

    public func wallpaperDirectoryPath() -> URL? {
        guard let basePath = fileManager.urls(
            for: .applicationSupportDirectory,
            in: FileManager.SearchPathDomainMask.userDomainMask).first
        else {
            logger.log("WallpaperFilePathProvider - error fetching basePath for application",
                       level: .debug,
                       category: .legacyHomepage)
            return nil
        }

        let wallpaperDirectoryPath = basePath.appendingPathComponent("wallpapers")
        createFolderAt(path: wallpaperDirectoryPath)

        return wallpaperDirectoryPath
    }

    // MARK: - Helper functions
    private func createFolderAt(path directoryPath: URL) {
        if !fileManager.fileExists(atPath: directoryPath.path) {
            do {
                try fileManager.createDirectory(atPath: directoryPath.path,
                                                withIntermediateDirectories: true,
                                                attributes: nil)
            } catch {
                logger.log("Could not create directory at \(directoryPath.absoluteString)",
                           level: .debug,
                           category: .legacyHomepage)
            }
        }
    }

    private func getFolderName(from input: String) -> String {
        // If the file is a thumbnail file, then return thumbnails as the
        // folder name. Otherwise, use the file name as the folder name.
        if input.hasSuffix(WallpaperFilenameIdentifiers.thumbnail) {
            return thumbnailsKey
        } else {
            return strip(
                [
                    WallpaperFilenameIdentifiers.portrait,
                    WallpaperFilenameIdentifiers.landscape,
                    WallpaperFilenameIdentifiers.iPad,
                    WallpaperFilenameIdentifiers.iPhone
                ],
                from: input)
        }
    }

    private func strip(_ identifiers: [String], from input: String) -> String {
        if identifiers.isEmpty { return input }

        return strip(identifiers.tail,
                     from: input.replacingOccurrences(of: identifiers[0], with: ""))
    }
}
