// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import UIKit
import Common

//MARK: Protocol
protocol TabDataStore {
    func fetchWindowData() async -> WindowData
    func saveWindowData(window: WindowData) async
    func clearAllWindowsData() async
}

actor DefaultTabDataStore: TabDataStore {
    //MARK: Variables
    let browserKitInfo = BrowserKitInformation.shared
    static let storePath = "codableWindowsState.archive"
    private let saveQueue = DispatchQueue(label: "com.example.tabdatastore.save")
    private var saveWorkItem: DispatchWorkItem?
    private let throttleInterval: TimeInterval = 5
    private var logger: Logger = DefaultLogger.shared

    //MARK: URL Utils
    private var windowDataDirectoryURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: browserKitInfo.sharedContainerIdentifier)?
            .appendingPathComponent("profile.profile")
    }

    private func windowURLPath(for windowId: UUID) -> URL? {
        if let profileURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: browserKitInfo.sharedContainerIdentifier)?
            .appendingPathComponent("profile.profile") {

            do {
                try FileManager.default.createDirectory(at: profileURL, withIntermediateDirectories: true, attributes: nil)
            } catch {
                logger.log("Error creating profile.profile directory: \(error)",
                           level: .debug,
                           category: .tabs)
                return nil
            }

            let filePath = DefaultTabDataStore.storePath + "_\(windowId.uuidString)"
            return profileURL.appendingPathComponent(filePath)
        }
        return nil
    }

    //MARK: Fetching Window Data
    func fetchWindowData() async -> WindowData {
        return WindowData(id: UUID(), isPrimary: true, activeTabId: UUID(), tabData: [])
    }

    func fetchWindowData(withId id: UUID) async -> WindowData? {
        guard let profileURL = windowDataDirectoryURL else {
            return nil
        }

        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(at: profileURL, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)

            let windowDataFiles = fileURLs.filter { $0.path.contains(DefaultTabDataStore.storePath) }

            for fileURL in windowDataFiles {
                do {
                    let data = try Data(contentsOf: fileURL)
                    let windowData = try JSONDecoder().decode(WindowData.self, from: data)
                    if windowData.id == id {
                        return windowData
                    }
                } catch {
                    logger.log("Error decoding window data: \(error)",
                               level: .debug,
                               category: .tabs)
                }
            }
        } catch {
            logger.log("Error fetching window data with ID: \(error)",
                       level: .debug,
                       category: .tabs)
        }

        return nil
    }

    func fetchAllWindowsData() async -> [WindowData] {
        guard let profileURL = windowDataDirectoryURL else {
            return []
        }

        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(at: profileURL, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)

            let windowDataFiles = fileURLs.filter { $0.path.contains(DefaultTabDataStore.storePath) }

            var windowsData: [WindowData] = []
            for fileURL in windowDataFiles {
                do {
                    let data = try Data(contentsOf: fileURL)
                    let windowData = try JSONDecoder().decode(WindowData.self, from: data)
                    windowsData.append(windowData)
                } catch {
                    logger.log("Error decoding window data: \(error)",
                               level: .debug,
                               category: .tabs)
                }
            }
            return windowsData
        } catch {
            logger.log("Error fetching all window data: \(error)",
                       level: .debug,
                       category: .tabs)
            return []
        }
    }

    //MARK: Saving Data
    func saveWindowData(window: WindowData) async {
        saveWorkItem?.cancel()

        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            Task.init(priority: .userInitiated) {
                if let windowSavingPath = await self.windowURLPath(for: window.id) {
                    do {
                        try await self.writeWindowData(windowData: window, to: windowSavingPath)
                    } catch {
                        await self.logger.log("Failed to save window data: \(error)",
                                   level: .debug,
                                   category: .tabs)
                    }
                }
            }
        }

        saveWorkItem = workItem
        saveQueue.asyncAfter(deadline: .now() + throttleInterval, execute: workItem)
    }

    private func writeWindowData(windowData: WindowData, to url: URL) async throws {
        try await withUnsafeThrowingContinuation { continuation in
            do {
                let data = try JSONEncoder().encode(windowData)
                try data.write(to: url, options: .atomicWrite)
                continuation.resume(returning: ())
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    //MARK: Deleting Window Data
    func clearWindowData(for id: UUID) async {
        guard let profileURL = windowDataDirectoryURL else {
            return
        }

        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(at: profileURL, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)

            let windowDataFiles = fileURLs.filter { $0.path.contains(DefaultTabDataStore.storePath) }

            for fileURL in windowDataFiles {
                do {
                    let data = try Data(contentsOf: fileURL)
                    let windowData = try JSONDecoder().decode(WindowData.self, from: data)
                    if windowData.id == id {
                        try FileManager.default.removeItem(at: fileURL)
                        return
                    }
                } catch {
                    logger.log("Error while clearing window data: \(error)",
                               level: .debug,
                               category: .tabs)
                }
            }
        } catch {
            logger.log("Error clearing window data for ID: \(error)",
                       level: .debug,
                       category: .tabs)
        }
    }

    func clearAllWindowsData() async {
        guard let profileURL = windowDataDirectoryURL else {
            return
        }

        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(at: profileURL, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)

            let windowDataFiles = fileURLs.filter { $0.path.contains(DefaultTabDataStore.storePath) }

            for fileURL in windowDataFiles {
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
