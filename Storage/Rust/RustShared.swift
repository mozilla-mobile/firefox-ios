/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import Deferred

private let log = Logger.syncLogger

public class RustShared {
    static func moveDatabaseFileToBackupLocation(databasePath: String) {
        let databaseURL = URL(fileURLWithPath: databasePath)
        let databaseContainingDirURL = databaseURL.deletingLastPathComponent()
        let baseFilename = databaseURL.lastPathComponent

        // Attempt to make a backup as long as the database file still exists.
        guard FileManager.default.fileExists(atPath: databasePath) else {
            // No backup was attempted since the database file did not exist.
            Sentry.shared.sendWithStacktrace(message: "The Rust database was deleted while in use", tag: SentryTag.rustLogins)
            return
        }

        Sentry.shared.sendWithStacktrace(message: "Unable to open Rust database", tag: SentryTag.rustLogins, severity: .warning, description: "Attempting to move '\(baseFilename)'")

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
            log.debug("Moving \(shmBaseFilename) and \(walBaseFilename)…")

            let shmDatabasePath = databaseContainingDirURL.appendingPathComponent(shmBaseFilename).path
            if FileManager.default.fileExists(atPath: shmDatabasePath) {
                log.debug("\(shmBaseFilename) exists.")
                try FileManager.default.moveItem(atPath: shmDatabasePath, toPath: "\(bakDatabasePath)-shm")
            }

            let walDatabasePath = databaseContainingDirURL.appendingPathComponent(walBaseFilename).path
            if FileManager.default.fileExists(atPath: walDatabasePath) {
                log.debug("\(walBaseFilename) exists.")
                try FileManager.default.moveItem(atPath: shmDatabasePath, toPath: "\(bakDatabasePath)-wal")
            }

            log.debug("Finished moving Rust database (\(baseFilename)) successfully.")
        } catch let error as NSError {
            Sentry.shared.sendWithStacktrace(message: "Unable to move Rust database to backup location", tag: SentryTag.rustLogins, severity: .error, description: "Attempted to move to '\(bakBaseFilename)'. \(error.localizedDescription)")
        }
    }
}
