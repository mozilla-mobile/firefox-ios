// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common
import Shared

public class RustShared {
    static func moveDatabaseFileToBackupLocation(databasePath: String,
                                                 logger: Logger = DefaultLogger.shared) {
        let databaseURL = URL(fileURLWithPath: databasePath)
        let databaseContainingDirURL = databaseURL.deletingLastPathComponent()
        let baseFilename = databaseURL.lastPathComponent

        // Attempt to make a backup as long as the database file still exists.
        guard FileManager.default.fileExists(atPath: databasePath) else {
            // No backup was attempted since the database file did not exist.
            logger.log("The Rust database was deleted while in use",
                       level: .info,
                       category: .storage)
            return
        }

        // Note that a backup file might already exist! We append a counter to avoid this.
        var bakCounter = 0
        var bakBaseFilename: String
        var bakDatabasePath: String
        repeat {
            bakCounter += 1
            bakBaseFilename = "\(baseFilename).bak.\(bakCounter)"
            bakDatabasePath = databaseContainingDirURL.appendingPathComponent(bakBaseFilename).path
        } while FileManager.default.fileExists(atPath: bakDatabasePath)

        do {
            try FileManager.default.moveItem(atPath: databasePath, toPath: bakDatabasePath)

            let shmBaseFilename = baseFilename + "-shm"
            let walBaseFilename = baseFilename + "-wal"
            logger.log("Moving database \(shmBaseFilename) and \(walBaseFilename)…",
                       level: .debug,
                       category: .storage)

            let shmDatabasePath = databaseContainingDirURL.appendingPathComponent(shmBaseFilename).path
            if FileManager.default.fileExists(atPath: shmDatabasePath) {
                try FileManager.default.moveItem(atPath: shmDatabasePath, toPath: "\(bakDatabasePath)-shm")
            }

            let walDatabasePath = databaseContainingDirURL.appendingPathComponent(walBaseFilename).path
            if FileManager.default.fileExists(atPath: walDatabasePath) {
                try FileManager.default.moveItem(atPath: shmDatabasePath, toPath: "\(bakDatabasePath)-wal")
            }

            logger.log("Finished moving Rust database \(baseFilename) successfully",
                       level: .debug,
                       category: .storage)
        } catch let error as NSError {
            logger.log("Unable to move Rust database to backup location",
                       level: .warning,
                       category: .storage,
                       description: "Attempted to move to '\(bakBaseFilename)'. \(error.localizedDescription)")
        }
    }
}
