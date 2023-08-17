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
    func saveTabSession(tabID: UUID, sessionData: Data) async

    /// Fetches the session data associated with a tab
    /// - Parameter tabID: an ID that uniquely identifies the tab
    /// - Returns: the data associated with a session, encoded as a Data object
    func fetchTabSession(tabID: UUID) async -> Data?
}

public actor DefaultTabSessionStore: TabSessionStore {
    let fileManager: TabFileManager
    let logger: Logger
    let filePrefix = "tab-"

    public init(fileManager: TabFileManager = DefaultTabFileManager(),
                logger: Logger = DefaultLogger.shared) {
        self.fileManager = fileManager
        self.logger = logger
    }

    public func saveTabSession(tabID: UUID, sessionData: Data) async {
        guard let directory = fileManager.tabSessionDataDirectory() else { return }

        if !fileManager.fileExists(atPath: directory) {
            fileManager.createDirectoryAtPath(path: directory)
        }

        let path = directory.appendingPathComponent(filePrefix + tabID.uuidString)
        do {
            try sessionData.write(to: path, options: .atomicWrite)
        } catch {
            logger.log("Failed to save session data with error: \(error.localizedDescription)",
                       level: .debug,
                       category: .tabs)
        }
    }

    public func fetchTabSession(tabID: UUID) async -> Data? {
        guard let path = fileManager.tabSessionDataDirectory()?.appendingPathComponent(filePrefix + tabID.uuidString)
        else { return nil }

        do {
            return try Data(contentsOf: path)
        } catch {
            logger.log("Failed to decode session data with error: \(error.localizedDescription)",
                       level: .debug,
                       category: .tabs)
            return nil
        }
    }
}
