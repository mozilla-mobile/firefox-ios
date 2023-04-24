// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common

public protocol TabSessionStore {
    /// The directory the session data should be stored at
    var filesDirectory: String { get }

    /// Saves the session data associated with a tab
    /// - Parameters:
    ///   - tabID: an ID that uniquely identifies the tab
    ///   - sessionData: the data associated with a session, encoded as a Data object
    func saveTabSession(tabID: UUID, sessionData: Data) async

    /// Fetches the session data associated with a tab
    /// - Parameter tabID: an ID that uniquely identifies the tab
    /// - Returns: the data associated with a session, encoded as a Data object
    func fetchTabSession(tabID: UUID) async -> Data

    /// Erases all session data files stored on disk
    func clearAllData() async
}

actor DefaultTabSessionStore {
    let fileManager: TabFileManager
    let logger: Logger

    init(fileManager: TabFileManager = DefaultTabFileManager(),
         logger: Logger = DefaultLogger.shared) {
        self.fileManager = fileManager
        self.logger = logger
    }

    func saveTabSession(tabID: UUID, sessionData: Data) async {
        guard let path = fileManager.tabDataDirectory()?.appendingPathComponent(tabID.uuidString) else { return }
        do {
            try sessionData.write(to: path, options: .atomicWrite)
        } catch {
            logger.log("Failed to save session data with error: \(error.localizedDescription)",
                       level: .debug,
                       category: .tabs)
        }
    }

    func fetchTabSession(tabID: UUID) async -> Data {
        // TODO: FXIOS-5882
        return Data()
    }

    func clearAllData() async {
        // TODO: FXIOS-6075
    }
}
