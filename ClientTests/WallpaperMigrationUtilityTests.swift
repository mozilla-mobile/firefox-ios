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
        removeAllFolders()
    }

    override func tearDown() {
        removeAllFolders()
    }

    func testRemovingAllFoldersOnSetup() {
        verifyFoldersHaveBeenDeleted(with: FileManager.default)
    }

    func testCreatingAFolder() {
        let fileManager = FileManager.default
        verifyFoldersHaveBeenDeleted(with: fileManager)

        guard let appSupportPath = path(for: .applicationSupport),
              let docsPath = path(for: .documents)
        else {
            XCTFail("Could not create paths")
            return
        }

        var isDirectory: ObjCBool = true
        createFolderAt(path: docsPath)
        createFolderAt(path: appSupportPath)

        XCTAssertTrue(fileManager.fileExists(atPath: docsPath.path,
                                              isDirectory: &isDirectory))
        XCTAssertTrue(fileManager.fileExists(atPath: appSupportPath.path,
                                              isDirectory: &isDirectory))

    }

    func testMigrationKeyDoesntExist() {
        let profile = MockProfile(databasePrefix: "wallpaperMigrationTests")
        XCTAssertNil(profile.prefs.boolForKey(migrationKey))
    }

    func testMigrationFlow() {
        let fileManager = FileManager.default
        verifyFoldersHaveBeenDeleted(with: fileManager)

        let profile = MockProfile(databasePrefix: "wallpaperMigrationTests")
        createFolderAt(path: path(for: .documents))
        WallpaperMigrationUtility(with: profile).attemptMigration()
        guard let key = profile.prefs.boolForKey(migrationKey) else {
            XCTFail("No key exists when a key should exist for WallpaperMigrationCheck")
            return
        }

        XCTAssertTrue(key, "After a migration, the key should be set to true, but it is not.")

        // Verify that the folder moved, and no longer exists in the
        // previous place.
        verifyAppSupportDirExistsAndDocsDirDoesNot(with: fileManager)
    }

    func testMigrationFlowIfNoFolderExists() {
        let fileManager = FileManager.default
        verifyFoldersHaveBeenDeleted(with: fileManager)

        let profile = MockProfile(databasePrefix: "wallpaperMigrationTests")
        WallpaperMigrationUtility(with: profile).attemptMigration()
        guard let key = profile.prefs.boolForKey(migrationKey) else {
            XCTFail("No key exists when a key should exist for WallpaperMigrationCheck")
            return
        }

        XCTAssertTrue(key, "WallpaperMigrationCheck should be true if no folder exists, but it is `false`")
    }

    func testMigrationFlowIfAppSupportFolderAlreadyExists() {
        let fileManager = FileManager.default
        verifyFoldersHaveBeenDeleted(with: fileManager)

        let profile = MockProfile(databasePrefix: "wallpaperMigrationTests")
        createFolderAt(path: path(for: .applicationSupport))
        WallpaperMigrationUtility(with: profile).attemptMigration()
        guard let key = profile.prefs.boolForKey(migrationKey) else {
            XCTFail("No key exists when a key should exist for WallpaperMigrationCheck")
            return
        }

        XCTAssertTrue(key, "After a migration, the key should be set to true, but it is not.")

        verifyAppSupportDirExistsAndDocsDirDoesNot(with: fileManager)
    }

    func testMigrationFlowIfBothDirectoriesAlreadyExist() {
        let fileManager = FileManager.default
        verifyFoldersHaveBeenDeleted(with: fileManager)

        let profile = MockProfile(databasePrefix: "wallpaperMigrationTests")
        createFolderAt(path: path(for: .applicationSupport))
        createFolderAt(path: path(for: .documents))
        WallpaperMigrationUtility(with: profile).attemptMigration()
        guard let key = profile.prefs.boolForKey(migrationKey) else {
            XCTFail("No key exists when a key should exist for WallpaperMigrationCheck")
            return
        }

        XCTAssertTrue(key, "After a migration, the key should be set to true, but it is not.")

        verifyAppSupportDirExistsAndDocsDirDoesNot(with: fileManager)
    }

    // MARK: - Helpers
    private func verifyFoldersHaveBeenDeleted(with fileManager: FileManager, file: StaticString = #filePath, line: UInt = #line) {
        guard let appSupportPath = path(for: .applicationSupport)?.path,
              let docsPath = path(for: .documents)?.path
        else {
            XCTFail("Could not create paths", file: file, line: line)
            return
        }

        var isDirectory: ObjCBool = true
        XCTAssertFalse(fileManager.fileExists(atPath: docsPath,
                                              isDirectory: &isDirectory),
                       file: file,
                       line: line)
        XCTAssertFalse(fileManager.fileExists(atPath: appSupportPath,
                                              isDirectory: &isDirectory),
                       file: file,
                       line: line)
    }

    private func verifyAppSupportDirExistsAndDocsDirDoesNot(with fileManager: FileManager, file: StaticString = #filePath, line: UInt = #line) {
        guard let appSupportPath = path(for: .applicationSupport),
              let docsPath = path(for: .documents)
        else {
            XCTFail("Could not create paths", file: file, line: line)
            return
        }

        var isDirectory: ObjCBool = true
        XCTAssertFalse(fileManager.fileExists(atPath: docsPath.path,
                                              isDirectory: &isDirectory),
                       file: file,
                       line: line)
        XCTAssertTrue(fileManager.fileExists(atPath: appSupportPath.path,
                                             isDirectory: &isDirectory),
                      file: file,
                      line: line)
    }

    private func createFolderAt(path directoryPath: URL?,
                                file: StaticString = #filePath,
                                line: UInt = #line
    ) {
        guard let directoryPath = directoryPath else { return }

        let fileManager = FileManager.default
        var isDirectory: ObjCBool = true
        if !fileManager.fileExists(atPath: directoryPath.path, isDirectory: &isDirectory) {
            do {
                try fileManager.createDirectory(atPath: directoryPath.path,
                                                withIntermediateDirectories: true,
                                                attributes: nil)
            } catch {
                XCTFail("Could not create directory at \(directoryPath.absoluteString)",
                        file: file,
                        line: line)
            }
        }
    }

    private func removeAllFolders() {
        let fileManager = FileManager.default
        guard let appSupportDir = path(for: .applicationSupport),
              let docsDir = path(for: .documents)
        else { return }

        var isDirectory: ObjCBool = true
        if fileManager.fileExists(atPath: docsDir.path, isDirectory: &isDirectory) {
            do {
                try fileManager.removeItem(at: docsDir)
            } catch let error {
                XCTFail("Deleting docs directory error: \(error.localizedDescription)")
            }
        }

        if fileManager.fileExists(atPath: appSupportDir.path, isDirectory: &isDirectory) {
            do {
                try fileManager.removeItem(at: appSupportDir)
            } catch let error {
                XCTFail("Deleting App Support directory error: \(error.localizedDescription)")
            }
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
            return documentPath.appendingPathComponent(WallpaperStorageUtility.directoryName)
        case .applicationSupport:
            return appSupportPath.appendingPathComponent(WallpaperStorageUtility.directoryName)
        }
    }
}
