// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common

public protocol TabDataStore {
    /// Fetches the previously saved window data (this contains the list of tabs) from disk, if it exists
    /// - Returns: The window data object if one was previously saved
    func fetchWindowData() async -> WindowData?

    /// Saves the window data (contains the list of tabs) to disk
    /// - Parameter window: the window data object to be saved
    func saveWindowData(window: WindowData, forced: Bool) async

    /// Erases all window data on disk
    func clearAllWindowsData() async
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

    public init(logger: Logger = DefaultLogger.shared,
                fileManager: TabFileManager = DefaultTabFileManager(),
                throttleTime: UInt64 = 2 * NSEC_PER_SEC) {
        self.logger = logger
        self.fileManager = fileManager
        self.throttleTime = throttleTime
    }

    // MARK: Fetching Window Data

    public func fetchWindowData() async -> WindowData? {
        logger.log("Attempting to fetch window/tab data",
                   level: .debug,
                   category: .tabs)
        let allWindows = await fetchAllWindowsData()
        return allWindows.first
    }

    private func fetchAllWindowsData() async -> [WindowData] {
        guard let directoryURL = fileManager.windowDataDirectory(isBackup: false) else {
            logger.log("Could not resolve window data directory",
                       level: .warning,
                       category: .tabs)
            return [WindowData]()
        }

        do {
            let fileURLs = fileManager.contentsOfDirectory(at: directoryURL)
            let windowsData = parseWindowDataFiles(fromURLs: fileURLs)
            if windowsData.isEmpty {
                if !fileURLs.isEmpty {
                    // There was a file present but it failed to restore for some reason
                    logger.log("Failed to open window/tab data",
                               level: .fatal,
                               category: .tabs)
                }
                throw TabDataError.failedToFetchData
            }
            return windowsData
        } catch {
            logger.log("Error fetching all window data: \(error)",
                       level: .warning,
                       category: .tabs)
            guard let backupURL = fileManager.windowDataDirectory(isBackup: true) else {
                return [WindowData]()
            }
            let fileURLs = fileManager.contentsOfDirectory(at: backupURL)
            let windowsData = parseWindowDataFiles(fromURLs: fileURLs)
            return windowsData
        }
    }

    private func parseWindowDataFiles(fromURLs urlList: [URL]) -> [WindowData] {
        var windowsData: [WindowData] = []
        for fileURL in urlList {
            do {
                if let windowData = try? fileManager.getWindowDataFromPath(path: fileURL) {
                    windowsData.append(windowData)
                }
            }
        }
        return windowsData
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

    // MARK: - URL Utils

    private func windowURLPath(for windowID: UUID, isBackup: Bool) -> URL? {
        guard let baseURL = fileManager.windowDataDirectory(isBackup: isBackup) else { return nil }
        let baseFilePath = "window-" + windowID.uuidString
        return baseURL.appendingPathComponent(baseFilePath)
    }
}
