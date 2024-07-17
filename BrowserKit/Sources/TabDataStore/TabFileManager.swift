// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common

public protocol TabFileManager {
    /// Determines the directory where tab session data should be stored
    /// - Returns: the URL that should be used for storing tab session data, can be nil
    func tabSessionDataDirectory() -> URL?

    /// Determines the directory where window data should be stored
    /// - Parameter isBackup: This determines which of the window data folders will be returned,
    /// the backup folder is used to store a slightly older copy of the data for use if the main copy becomes corrupted
    /// - Returns: the URL that should be used for storing window data, can be nil
    func windowDataDirectory(isBackup: Bool) -> URL?

    /// Returns the contents at a given directory
    /// - Parameter path: the location to check
    /// - Returns: a list of file URL's at the given location
    func contentsOfDirectory(at path: URL) -> [URL]

    /// Moves a file from one location to another
    /// - Parameters:
    ///   - sourceURL: the location of the file to be moved
    ///   - destinationURL: the location of where the file is to be moved to
    func copyItem(at sourceURL: URL, to destinationURL: URL) throws

    /// Removes all files at a given location
    /// - Parameter directory: the location of the files to remove
    func removeAllFilesAt(directory: URL)

    /// Checks if a file exists at the given location
    /// - Parameter pathURL: the location of the file to check
    /// - Returns: returns true if a file exists at this location
    func fileExists(atPath pathURL: URL) -> Bool

    /// Creates a directory at the given location
    /// - Parameter path: the location to create the directory
    func createDirectoryAtPath(path: URL)

    /// Returns the decoded window data from the file path given
    /// - Parameter path: the file path of the data to be decoded
    /// - Returns: a window data object if it can be decoded
    func getWindowDataFromPath(path: URL) throws -> WindowData?

    /// Writes the window data to file at the given location
    /// - Parameters:
    ///   - windowData: the window data to be saved
    ///   - url: the directory to save the data to
    func writeWindowData(windowData: WindowData, to url: URL) throws

    /// Removes the file at the given URL.
    /// - Parameter path: the file to be removed.
    func removeFileAt(path: URL)
}

public struct DefaultTabFileManager: TabFileManager {
    enum PathInfo {
        static let rootDirectory = "profile.profile"
        static let tabSessionData = "tab-session-data"
        static let primary = "window-data"
        static let backup = "window-data-backup"
    }

    let fileManager: FileManager
    let logger: Logger

    public init(fileManager: FileManager = FileManager.default,
                logger: Logger = DefaultLogger.shared) {
        self.fileManager = fileManager
        self.logger = logger
    }

    public func tabSessionDataDirectory() -> URL? {
        guard let containerID = BrowserKitInformation.shared.sharedContainerIdentifier else { return nil }
        var containerURL = fileManager.containerURL(forSecurityApplicationGroupIdentifier: containerID)
        containerURL = containerURL?.appendingPathComponent(PathInfo.rootDirectory)
        return containerURL?.appendingPathComponent(PathInfo.tabSessionData)
    }

    public func windowDataDirectory(isBackup: Bool) -> URL? {
        guard let containerID = BrowserKitInformation.shared.sharedContainerIdentifier else {
            logger.log(
                "Failed to get the window data container ID from BrowserKit's sharedContainerIdentifier",
                level: .warning,
                category: .tabs
            )
            return nil
        }
        let pathInfo = isBackup ? PathInfo.backup : PathInfo.primary
        guard let containerURL = fileManager.containerURL(forSecurityApplicationGroupIdentifier: containerID) else {
            logger.log("Failed to get the window data container URL", level: .warning, category: .tabs)
            return nil
        }
        let appendedURL = containerURL.appendingPathComponent(PathInfo.rootDirectory)
        return appendedURL.appendingPathComponent(pathInfo)
    }

    public func contentsOfDirectory(at path: URL) -> [URL] {
        do {
            return try fileManager.contentsOfDirectory(
                    at: path,
                    includingPropertiesForKeys: nil,
                    options: .skipsHiddenFiles)
        } catch {
            return []
        }
    }

    public func copyItem(at sourceURL: URL, to destinationURL: URL) throws {
        // Ensure there is no file at the destination as copy cannot overwrite
        try? fileManager.removeItem(at: destinationURL)
        try fileManager.copyItem(at: sourceURL, to: destinationURL)
    }

    public func removeFileAt(path: URL) {
        do {
            try fileManager.removeItem(at: path)
            return
        } catch {
            logger.log("Error while clearing window data: \(error)",
                       level: .debug,
                       category: .tabs)
        }
    }

    public func removeAllFilesAt(directory: URL) {
        let fileURLs = contentsOfDirectory(at: directory)
        for fileURL in fileURLs {
            removeFileAt(path: fileURL)
        }
    }

    public func fileExists(atPath pathURL: URL) -> Bool {
        return fileManager.fileExists(atPath: pathURL.path)
    }

    public func createDirectoryAtPath(path: URL) {
        do {
            try fileManager.createDirectory(at: path, withIntermediateDirectories: true)
        } catch {
            logger.log("Failed to create directory: \(error.localizedDescription) for path: \(path.path)",
                       level: .debug,
                       category: .tabs)
        }
    }

    public func getWindowDataFromPath(path: URL) throws -> WindowData? {
        do {
            let data = try Data(contentsOf: path)
            let windowData = try JSONDecoder().decode(WindowData.self, from: data)
            return windowData
        } catch {
            logger.log("Error decoding window data: \(error)",
                       level: .warning,
                       category: .tabs)
            throw error
        }
    }

    public func writeWindowData(windowData: WindowData, to url: URL) throws {
        let data = try JSONEncoder().encode(windowData)
        try data.write(to: url, options: .atomicWrite)
    }
}
