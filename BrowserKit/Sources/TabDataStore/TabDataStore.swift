// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common

public protocol TabDataStore {
    func fetchWindowData() async -> WindowData?
    func saveWindowData(window: WindowData) async
    func clearAllWindowsData() async
}

public actor DefaultTabDataStore: TabDataStore {
    private let logger: Logger
    private let fileManager: TabFileManager
    private let throttleTime: UInt64
    private var windowDataToSave: WindowData?
    private var nextSaveIsScheduled = false

    public init(logger: Logger = DefaultLogger.shared,
                fileManager: TabFileManager = DefaultTabFileManager(),
                throttleTime: UInt64 = 5 * NSEC_PER_SEC) {
        self.logger = logger
        self.fileManager = fileManager
        self.throttleTime = throttleTime
    }

    // MARK: - URL Utils

    private func windowURLPath(for windowID: UUID, isBackup: Bool) -> URL? {
        guard let baseURL = fileManager.windowDataDirectory(isBackup: isBackup) else { return nil }
        let baseFilePath = "window-" + windowID.uuidString
        return baseURL.appendingPathComponent(baseFilePath)
    }

    // MARK: Fetching Window Data

    public func fetchWindowData() async -> WindowData? {
        let allWindows = await fetchAllWindowsData()
        return allWindows.first
    }

    private func fetchWindowData(withID id: UUID, isBackup: Bool) async -> WindowData? {
        guard let directoryURL = windowURLPath(for: id, isBackup: isBackup) else {
            return nil
        }
        do {
            let windowData = try await decodeWindowData(from: directoryURL)
            return windowData
        } catch {
            return nil
        }
    }

    private func fetchWindowData(withID id: UUID) async -> WindowData? {
        guard let directoryURL = windowURLPath(for: id, isBackup: false) else {
            return nil
        }
        do {
            let windowData = try await decodeWindowData(from: directoryURL)
            return windowData
        } catch {
            logger.log("Error fetching window data: \(error)",
                       level: .debug,
                       category: .tabs)
            guard let backupURL = fileManager.windowDataDirectory(isBackup: true) else {
                return nil
            }
            do {
                let backupWindowData = try await decodeWindowData(from: backupURL)
                return backupWindowData
            } catch {
                logger.log("Error fetching backup window data: \(error)",
                           level: .debug,
                           category: .tabs)
            }
            return nil
        }
    }

    private func fetchAllWindowsData() async -> [WindowData] {
        guard let directoryURL = fileManager.windowDataDirectory(isBackup: false) else {
            return [WindowData]()
        }

        do {
            let fileURLs = fileManager.contentsOfDirectory(at: directoryURL)
            let windowsData = try await parseWindowDataFiles(fromURLs: fileURLs)
            return windowsData
        } catch {
            logger.log("Error fetching all window data: \(error)",
                       level: .debug,
                       category: .tabs)
            guard let backupURL = fileManager.windowDataDirectory(isBackup: true) else {
                return [WindowData]()
            }
            do {
                let fileURLs = fileManager.contentsOfDirectory(at: backupURL)
                let windowsData = try await parseWindowDataFiles(fromURLs: fileURLs)
                return windowsData
            } catch {
                logger.log("Error fetching all window data from backup: \(error)",
                           level: .debug,
                           category: .tabs)
                return [WindowData]()
            }
        }
    }

    private func parseWindowDataFiles(fromURLs urlList: [URL]) async throws -> [WindowData] {
        var windowsData: [WindowData] = []
        for fileURL in urlList {
            do {
                let windowData = try await decodeWindowData(from: fileURL)
                windowsData.append(windowData)
            }
        }
        return windowsData
    }

    private func decodeWindowData(from fileURL: URL) async throws -> WindowData {
        do {
            let data = try Data(contentsOf: fileURL)
            let windowData = try JSONDecoder().decode(WindowData.self, from: data)
            return windowData
        } catch {
            logger.log("Error decoding window data: \(error)",
                       level: .debug,
                       category: .tabs)
            throw error
        }
    }

    // MARK: - Saving Data

    public func saveWindowData(window: WindowData) async {
        guard let windowSavingPath = windowURLPath(for: window.id, isBackup: false) else { return }

        if fileManager.fileExists(atPath: windowSavingPath) {
            createWindowDataBackup(window: window, windowSavingPath: windowSavingPath)
        } else {
            if let windowDataDirectoryURL = fileManager.windowDataDirectory(isBackup: false),
               !fileManager.fileExists(atPath: windowDataDirectoryURL) {
                fileManager.createDirectoryAtPath(path: windowDataDirectoryURL)
            }
        }
        await writeWindowDataToFileWithThrottle(window: window, path: windowSavingPath)
    }

    private func createWindowDataBackup(window: WindowData, windowSavingPath: URL) {
        guard let backupWindowSavingPath = windowURLPath(for: window.id, isBackup: true),
              let backupDirectoryPath = fileManager.windowDataDirectory(isBackup: true) else {
            return
        }
        if !fileManager.fileExists(atPath: backupDirectoryPath) {
            fileManager.createDirectoryAtPath(path: backupDirectoryPath)
        }
        do {
            try fileManager.copyItem(at: windowSavingPath, to: backupWindowSavingPath)
        } catch {
            logger.log("Failed to create window data backup: \(error)",
                       level: .debug,
                       category: .tabs)
        }
    }

    // Throttles the saving of the data so that it happens every 'throttleTime' nanoseconds
    // as long as their is new data to be saved
    private func writeWindowDataToFileWithThrottle(window: WindowData, path: URL) async {
        // Hold onto a copy of the latest window data so whenever the save happens it is using the latest
        windowDataToSave = window

        // Ignore the request because a save is already scheduled to happen
        guard !nextSaveIsScheduled else { return }

        // Set the guard bool to true so no new saves can be initiated while waiting
        nextSaveIsScheduled = true

        // Dispatch to a task so as not to block the caller
        Task {
            // Once the throttle time has passed initiate the save and reset the bool
            try? await Task.sleep(nanoseconds: throttleTime)
            nextSaveIsScheduled = false

            do {
                guard let windowDataToSave = windowDataToSave else {
                    logger.log("Tried to save window data but found nil",
                               level: .fatal,
                               category: .tabs)
                    return
                }
                try await writeWindowData(windowData: windowDataToSave, to: path)
            } catch {
                logger.log("Failed to save window data: \(error)",
                           level: .debug,
                           category: .tabs)
            }
        }
    }

    private func writeWindowData(windowData: WindowData, to url: URL) async throws {
        let data = try JSONEncoder().encode(windowData)
        try data.write(to: url, options: .atomicWrite)
    }

    // MARK: - Deleting Window Data

    private func clearWindowData(for id: UUID) async {
        guard let directoryURL = windowURLPath(for: id, isBackup: false) else {
            return
        }
        guard let backupURL = windowURLPath(for: id, isBackup: true) else {
            return
        }
        fileManager.removeFileAt(path: directoryURL)
        fileManager.removeFileAt(path: backupURL)
    }

    public func clearAllWindowsData() async {
        guard let directoryURL = fileManager.windowDataDirectory(isBackup: false),
              let backupURL = fileManager.windowDataDirectory(isBackup: true) else {
            return
        }
        fileManager.removeAllFilesAt(directory: directoryURL)
        fileManager.removeAllFilesAt(directory: backupURL)
    }
}
