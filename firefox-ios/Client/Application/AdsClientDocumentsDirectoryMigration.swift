// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Shared

struct AdsClientDocumentsDirectoryMigration {
    private static let databaseFileNames = ["ads-client.db", "ads-client-staging.db"]
    private static let databaseFileSuffixes = ["", "-shm", "-wal", "-journal"]
    private static var legacyDatabaseFileNames: [String] {
        databaseFileNames.flatMap { databaseFileName in
            databaseFileSuffixes.map { "\(databaseFileName)\($0)" }
        }
    }

    private let fileManager: FileManagerProtocol
    private let logger: Logger
    private let userDefaults: UserDefaultsInterface

    init(
        fileManager: FileManagerProtocol = FileManager.default,
        logger: Logger = DefaultLogger.shared,
        userDefaults: UserDefaultsInterface = UserDefaults.standard
    ) {
        self.fileManager = fileManager
        self.logger = logger
        self.userDefaults = userDefaults
    }

    func removeLegacyDatabaseFiles() {
        guard !userDefaults.bool(forKey: PrefsKeys.AdsClient.documentsDirectoryMigrationCheck) else { return }

        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            logger.log("Unable to resolve Documents directory for ads client cleanup",
                       level: .warning,
                       category: .storage)
            return
        }

        let didFailToRemoveFile = Self.legacyDatabaseFileNames
            .map { documentsURL.appendingPathComponent($0) }
            .reduce(false) { didFail, databaseURL in
                guard fileManager.fileExists(atPath: databaseURL.path) else { return didFail }

                do {
                    try fileManager.removeItem(at: databaseURL)
                    return didFail
                } catch {
                    logger.log("Failed to remove legacy ads client database",
                               level: .warning,
                               category: .storage,
                               extra: ["error": error.localizedDescription])
                    return true
                }
            }

        if !didFailToRemoveFile {
            userDefaults.set(true, forKey: PrefsKeys.AdsClient.documentsDirectoryMigrationCheck)
        }
    }
}
