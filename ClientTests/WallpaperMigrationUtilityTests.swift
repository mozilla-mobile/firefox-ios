// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import XCTest
import Shared

@testable import Client

class WallpaperMigrationUtilityTests: XCTestCase {

    private let migrationKey = PrefsKeys.LegacyFeatureFlags.WallpaperDirectoryMigrationCheck

    override func setUp() {
    }

    override func tearDown() {
    }

    func testMigrationKeyDoesntExist() {
        let profile = MockProfile(databasePrefix: "wallpaperMigrationTests")
        XCTAssertNil(profile.prefs.boolForKey(migrationKey))
    }

    func testPerformedCheck() throws {
        let profile = MockProfile(databasePrefix: "wallpaperMigrationTests")

        WallpaperMigrationUtility(with: profile).attemptMigration()
        let key = try XCTUnwrap(profile.prefs.boolForKey(migrationKey))

        XCTAssertTrue(key, "After a succesful migration, the key should be set to true, but it is not.")
    }

    // MARK: - Helpers
    private func createFolderAt(path directoryPath: URL) {
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: directoryPath.path) {
            do {
                try fileManager.createDirectory(atPath: directoryPath.path,
                                                withIntermediateDirectories: true,
                                                attributes: nil)
            } catch {
                XCTFail("Could not create directory at \(directoryPath.absoluteString)")
            }
        }
    }

    private func removeAllFolders() {
        let fileManager = FileManager.default
        guard let appSupportDir = path(for: .applicationSupport),
              let docsDir = path(for: .documents)
        else { return }

        do {
            try fileManager.removeItem(at: appSupportDir)
            try fileManager.removeItem(at: docsDir)
        } catch let error {
            XCTFail("Deleting docs error: \(error.localizedDescription)")
        }
    }

    private enum FolderPathForDirectory {
        case documents
        case applicationSupport
    }

    private func path(for directoryType: FolderPathForDirectory) -> URL? {
        let fileManager = FileManager.default
        guard let documentPath = fileManager.urls(for: .documentDirectory, in: FileManager.SearchPathDomainMask.userDomainMask).first,
              let appSupportPath = fileManager.urls(for: .applicationSupportDirectory, in: FileManager.SearchPathDomainMask.userDomainMask).first
        else { return nil }

        switch directoryType {
        case .documents:
            return documentPath.appendingPathComponent("wallpapers")
        case .applicationSupport:
            return appSupportPath.appendingPathComponent("wallpapers")
        }

//        do {
//            try fileManager.removeItem(at: wallpaperAppSupportDirectoryPath)
//            try fileManager.moveItem(at: wallpaperDocumentDirectoryPath,
//                             to: wallpaperAppSupportDirectoryPath)
//            try fileManager.removeItem(at: wallpaperDocumentDirectoryPath)
//        }
    }
}
