// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common

// MARK: Protocol
public protocol TabDataStore {
    func fetchWindowData() async -> WindowData
    func saveWindowData(window: WindowData) async
    func clearAllWindowsData() async
    func fetchWindowData(withID id: UUID) async -> WindowData?
    func fetchAllWindowsData() async -> [WindowData]
    func clearWindowData(for id: UUID) async
}

public actor DefaultTabDataStore: TabDataStore {
    // MARK: Variables
    let browserKitInfo = BrowserKitInformation.shared
    static let storePath = "codableWindowsState.archive"
    static let profilePath = "profile.profile"
    private var logger: Logger = DefaultLogger.shared

    public init() {}

    // MARK: URL Utils
    private var windowDataDirectoryURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: browserKitInfo.sharedContainerIdentifier)?
            .appendingPathComponent(DefaultTabDataStore.profilePath)
    }

    private func windowURLPath(for windowID: UUID) -> URL? {
        if let profileURL = windowDataDirectoryURL {
            let filePath = DefaultTabDataStore.storePath + "_\(windowID.uuidString)"
            let windowProfileURL = profileURL.appendingPathComponent(filePath)
            return windowProfileURL
        }
        return nil
    }

    // MARK: Fetching Window Data
    public func fetchWindowData() async -> WindowData {
        return WindowData(id: UUID(), isPrimary: true, activeTabId: UUID(), tabData: [])
    }

    public func fetchWindowData(withID id: UUID) async -> WindowData? {
        guard let profileURL = self.windowURLPath(for: id) else {
            return nil
        }
        do {
            let windowData = try await decodeWindowData(from: profileURL)
            return windowData
        } catch {
            return nil
        }
    }

    public func fetchAllWindowsData() async -> [WindowData] {
        guard let profileURL = windowDataDirectoryURL else {
            return []
        }

        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(
                at: profileURL,
                includingPropertiesForKeys: nil,
                options: .skipsHiddenFiles)
            var windowsData: [WindowData] = []
            for fileURL in fileURLs {
                do {
                    let windowData = try await decodeWindowData(from: fileURL)
                    windowsData.append(windowData)
                }
            }
            return windowsData
        } catch {
            logger.log("Error fetching all window data: \(error)",
                       level: .debug,
                       category: .tabs)
            return [WindowData]()
        }
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

    // MARK: Saving Data
    public func saveWindowData(window: WindowData) async {
        Task {
            if let windowSavingPath = self.windowURLPath(for: window.id) {
                do {
                    try await self.writeWindowData(windowData: window, to: windowSavingPath)
                } catch {
                    self.logger.log("Failed to save window data: \(error)",
                                    level: .debug,
                                    category: .tabs)
                }
            }
        }
    }

    private func writeWindowData(windowData: WindowData, to url: URL) async throws {
        do {
            let data = try JSONEncoder().encode(windowData)
            try data.write(to: url, options: .atomicWrite)
        } catch {
            throw error
        }
    }

    // MARK: Deleting Window Data
    public func clearWindowData(for id: UUID) async {
        guard let profileURL = self.windowURLPath(for: id) else {
            return
        }

        do {
            try FileManager.default.removeItem(at: profileURL)
            return
        } catch {
            logger.log("Error while clearing window data: \(error)",
                       level: .debug,
                       category: .tabs)
        }
    }

    public func clearAllWindowsData() async {
        guard let profileURL = windowDataDirectoryURL else {
            return
        }

        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(
                at: profileURL,
                includingPropertiesForKeys: nil,
                options: .skipsHiddenFiles)
            for fileURL in fileURLs {
                do {
                    try FileManager.default.removeItem(at: fileURL)
                } catch {
                    logger.log("Error while clearing all window data: \(error)",
                               level: .debug,
                               category: .tabs)
                }
            }
        } catch {
            logger.log("Error fetching all window data for clearing: \(error)",
                       level: .debug,
                       category: .tabs)
        }
    }
}
