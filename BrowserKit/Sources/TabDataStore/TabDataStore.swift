// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common

public protocol TabDataStore {
    /// Fetches the previously saved window data matching the provided UUID,
    /// if it exists. This data contains the list of tabs.
    /// - Returns: The window data object if one was previously saved
    func fetchWindowData(uuid: UUID) async -> WindowData?

    /// Saves the window data (contains the list of tabs) to disk
    /// - Parameter window: the window data object to be saved
    func saveWindowData(window: WindowData, forced: Bool) async

    /// Erases all window data on disk
    func clearAllWindowsData() async

    /// Synchronous function that lists UUIDs for all WindowData currently saved
    /// to disk. Because this requires no decoding (we can just check the list of
    /// saved files in the directory) it is faster than fetchWindowData() and is
    /// preferable when only the UUIDs are needed.
    /// - Returns: a list of UUIDs for any saved WindowData.
    func fetchWindowDataUUIDs() -> [WindowUUID]

    /// Erases the on-disk data for tab windows matching the provided UUIDs.
    /// - Parameter forUUIDs: the UUIDs to delete the on-disk tab files for.
    func removeWindowData(forUUIDs: [WindowUUID]) async
}

public actor DefaultTabDataStore: TabDataStore {
    enum TabDataError: Error {
        case failedToFetchData
    }

    private let logger: Logger
    private let fileManager: TabFileManager
    private let throttleTime: UInt64
    private var windowDataToSave: WindowData?
    private var nextSaveIsScheduled = false
    private let filePrefix = "window-"

    public init(logger: Logger = DefaultLogger.shared,
                fileManager: TabFileManager = DefaultTabFileManager(),
                throttleTime: UInt64 = 2 * NSEC_PER_SEC) {
        self.logger = logger
        self.fileManager = fileManager
        self.throttleTime = throttleTime
    }

    // MARK: Fetching Window Data

    public func fetchWindowData(uuid: UUID) async -> WindowData? {
        logger.log("Attempting to fetch window data", level: .debug, category: .tabs)

        // Adding more logging for FXIOS-9517
        var shouldLogFileFailure = false // Whether pulling from the main file failed
        var shouldLogBackupFailure = false // Whether pulling from the backup file failed
        var fileInfoMessage = "" // Specifics of main file failure
        var backupInfoMessage = "" // Specifics of backup file failure
        defer {
            if shouldLogFileFailure {
                let errorMessage: String
                errorMessage = shouldLogBackupFailure
                                ? "Failed to open window data (including backup data) for UUID: \(uuid)"
                                : "Failed to open window data (but backup recovery worked) for UUID: \(uuid)"
                logger.log(
                    "\(errorMessage) File Info: [\(fileInfoMessage)] Backup File Info: [\(backupInfoMessage)]",
                    level: .fatal,
                    category: .tabs
                )
            }
        }

        do {
            guard let fileURL = windowURLPath(for: uuid, isBackup: false) else {
                fileInfoMessage += "fileURL nil"
                shouldLogFileFailure = true
                throw TabDataError.failedToFetchData
            }

            guard fileManager.fileExists(atPath: fileURL) else {
                fileInfoMessage += "file doesn't exist"
                shouldLogFileFailure = true
                throw TabDataError.failedToFetchData
            }

            guard let windowData = parseWindowDataFile(fromURL: fileURL) else {
                fileInfoMessage += "file parsing failed"
                shouldLogFileFailure = true
                throw TabDataError.failedToFetchData
            }

            logger.log("Successfully fetched window data", level: .debug, category: .tabs)
            return windowData
        } catch {
            logger.log("Error fetching window data for UUID: \(uuid) Error: \(error)", level: .warning, category: .tabs)

            guard let backupURL = windowURLPath(for: uuid, isBackup: true) else {
                backupInfoMessage += "backup fileURL nil"
                shouldLogBackupFailure = true
                return nil
            }

            guard fileManager.fileExists(atPath: backupURL) else {
                backupInfoMessage += "backup file doesn't exist"
                shouldLogBackupFailure = true
                return nil
            }

            guard let backupWindowData = parseWindowDataFile(fromURL: backupURL) else {
                backupInfoMessage += "backup file parsing failed"
                shouldLogBackupFailure = true
                return nil
            }

            logger.log("Returned backup window data for UUID: \(uuid)", level: .debug, category: .tabs)
            return backupWindowData
        }
    }

    nonisolated public func fetchWindowDataUUIDs() -> [WindowUUID] {
        guard let directoryURL = fileManager.windowDataDirectory(isBackup: false) else {
            logger.log("Could not resolve window data directory", level: .warning, category: .tabs)
            return []
        }

        let fileURLs = fileManager.contentsOfDirectory(at: directoryURL)

        return fileURLs.compactMap { windowUUID(fromURL: $0) }
    }

    private func parseWindowDataFile(fromURL url: URL) -> WindowData? {
        return try? fileManager.getWindowDataFromPath(path: url)
    }

    // MARK: - Saving Data

    public func saveWindowData(window: WindowData, forced: Bool) async {
        guard let windowSavingPath = windowURLPath(for: window.id, isBackup: false) else { return }

        // Hold onto a copy of the latest window data so whenever the save happens it is using the latest
        windowDataToSave = window

        if let windowDataDirectoryURL = fileManager.windowDataDirectory(isBackup: false),
           !fileManager.fileExists(atPath: windowDataDirectoryURL) {
            fileManager.createDirectoryAtPath(path: windowDataDirectoryURL)
        }

        logger.log("Save window data, is forced: \(forced)",
                   level: .debug,
                   category: .tabs)
        if forced {
            await writeWindowDataToFile(path: windowSavingPath)
        } else {
            await writeWindowDataToFileWithThrottle(path: windowSavingPath)
        }
    }

    private func createWindowDataBackup(windowPath: URL) {
        guard let windowID = windowDataToSave?.id,
              let backupWindowSavingPath = windowURLPath(for: windowID, isBackup: true),
              let backupDirectoryPath = fileManager.windowDataDirectory(isBackup: true)
        else { return }

        if !fileManager.fileExists(atPath: backupDirectoryPath) {
            fileManager.createDirectoryAtPath(path: backupDirectoryPath)
        }
        do {
            try fileManager.copyItem(at: windowPath, to: backupWindowSavingPath)
        } catch {
            logger.log("Failed to create window data backup: \(error)",
                       level: .warning,
                       category: .tabs)
        }
    }

    // Throttles the saving of the data so that it happens every 'throttleTime' nanoseconds
    // as long as their is new data to be saved
    private func writeWindowDataToFileWithThrottle(path: URL) async {
        // Ignore the request because a save is already scheduled to happen
        guard !nextSaveIsScheduled else { return }

        // Set the guard bool to true so no new saves can be initiated while waiting
        nextSaveIsScheduled = true

        // Dispatch to a task so as not to block the caller
        Task {
            // Once the throttle time has passed initiate the save and reset the bool
            try? await Task.sleep(nanoseconds: throttleTime)
            nextSaveIsScheduled = false
            if fileManager.fileExists(atPath: path) {
                createWindowDataBackup(windowPath: path)
            }
            await writeWindowDataToFile(path: path)
        }
    }

    private func writeWindowDataToFile(path: URL) async {
        do {
            guard let windowDataToSave = windowDataToSave else {
                logger.log("Tried to save window data but found nil",
                           level: .fatal,
                           category: .tabs)
                return
            }
            try fileManager.writeWindowData(windowData: windowDataToSave, to: path)
        } catch {
            logger.log("Failed to save window data: \(error)",
                       level: .warning,
                       category: .tabs)
        }
    }

    // MARK: - Deleting Window Data

    public func clearAllWindowsData() async {
        guard let directoryURL = fileManager.windowDataDirectory(isBackup: false),
              let backupURL = fileManager.windowDataDirectory(isBackup: true) else {
            return
        }
        fileManager.removeAllFilesAt(directory: directoryURL)
        fileManager.removeAllFilesAt(directory: backupURL)
    }

    public func removeWindowData(forUUIDs uuids: [WindowUUID]) async {
        guard let directoryURL = fileManager.windowDataDirectory(isBackup: false) else { return }

        let fileURLs = fileManager.contentsOfDirectory(at: directoryURL)

        for url in fileURLs {
            guard let uuid = windowUUID(fromURL: url) else { continue }
            guard uuids.contains(where: { $0 == uuid }) else {
                logger.log("Will not remove window data for UUID: \(uuid)", level: .info, category: .tabs)
                continue
            }
            logger.log("Removing window data for UUID: \(uuid)", level: .info, category: .tabs)
            fileManager.removeFileAt(path: url)
        }
    }

    // MARK: - URL Utils

    private func windowURLPath(for windowID: UUID, isBackup: Bool) -> URL? {
        guard let baseURL = fileManager.windowDataDirectory(isBackup: isBackup) else { return nil }
        let baseFilePath = filePrefix + windowID.uuidString
        return baseURL.appendingPathComponent(baseFilePath)
    }

    /// For a URL that points to a window tab data file, returns the associated UUID
    /// for that window based on the file name.
    /// - Parameter url: the URL to parse.
    /// - Returns: a window UUID or nil if the URL was invalid.
    private nonisolated func windowUUID(fromURL url: URL) -> WindowUUID? {
        let file = url.lastPathComponent
        guard file.hasPrefix(filePrefix) else { return nil }
        let uuidString = String(file.dropFirst(filePrefix.count))
        return WindowUUID(uuidString: uuidString)
    }
}
