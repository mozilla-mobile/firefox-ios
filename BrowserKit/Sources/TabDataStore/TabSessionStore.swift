// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common

public protocol TabSessionStore {
    /// Saves the session data associated with a tab
    /// - Parameters:
    ///   - tabID: an ID that uniquely identifies the tab
    ///   - sessionData: the data associated with a session, encoded as a Data object
    func saveTabSession(tabID: UUID, sessionData: Data)

    /// Fetches the session data associated with a tab
    /// - Parameter tabID: an ID that uniquely identifies the tab
    /// - Returns: the data associated with a session, encoded as a Data object
    func fetchTabSession(tabID: UUID) -> Data?

    /// Cleans up any tab session data files for tabs that are no longer open.
    func deleteUnusedTabSessionData(keeping: [UUID]) async
}

public class DefaultTabSessionStore: TabSessionStore {
    let fileManager: TabFileManager
    let logger: Logger
    let filePrefix = "tab-"
    private let lock = NSRecursiveLock()

    public init(fileManager: TabFileManager = DefaultTabFileManager(),
                logger: Logger = DefaultLogger.shared) {
        self.fileManager = fileManager
        self.logger = logger
    }

    public func saveTabSession(tabID: UUID, sessionData: Data) {
        guard let directory = fileManager.tabSessionDataDirectory() else { return }

        if !fileManager.fileExists(atPath: directory) {
            fileManager.createDirectoryAtPath(path: directory)
        }

        let path = directory.appendingPathComponent(filePrefix + tabID.uuidString)
        do {
            lock.lock()
            defer { lock.unlock() }
            try sessionData.write(to: path, options: .atomicWrite)
        } catch {
            logger.log("Failed to save session data with error: \(error.localizedDescription)",
                       level: .debug,
                       category: .tabs)
        }
    }

    public func fetchTabSession(tabID: UUID) -> Data? {
        guard let path = fileManager.tabSessionDataDirectory()?.appendingPathComponent(filePrefix + tabID.uuidString)
        else { return nil }

        do {
            lock.lock()
            defer { lock.unlock() }
            return try Data(contentsOf: path)
        } catch {
            logger.log("Failed to decode session data with error: \(error.localizedDescription)",
                       level: .debug,
                       category: .tabs)
            return nil
        }
    }

    public func deleteUnusedTabSessionData(keeping: [UUID]) async {
        guard let directory = fileManager.tabSessionDataDirectory() else { return }
        let contents = fileManager.contentsOfDirectory(at: directory)
        guard !contents.isEmpty else { return }

        let liveTabs = keeping.compactMap { $0.uuidString }

        // This is O(m*n) but in general the performance here should not be problematic
        // since this will be performed off the main thread, and it will only be operating
        // on files for dead tabs that won't be accessed by any other code.
        for fileURL in contents {
            guard fileURL.lastPathComponent.hasPrefix(filePrefix) else { continue }
            let tabID = String(fileURL.lastPathComponent.dropFirst(filePrefix.count))
            guard !liveTabs.contains(tabID) else { continue }
            fileManager.removeFileAt(path: fileURL)
        }
    }
}
