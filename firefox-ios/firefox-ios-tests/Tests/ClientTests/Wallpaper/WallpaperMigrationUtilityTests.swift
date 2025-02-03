// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import XCTest
import Shared

@testable import Client

class WallpaperMigrationUtilityTests: XCTestCase {
    override func setUp() {
        super.setUp()
        removeAllFolders()
    }

    override func tearDown() {
        removeAllFolders()
        super.tearDown()
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

    // MARK: - Helpers
    private func verifyFoldersHaveBeenDeleted(
        with fileManager: FileManager,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
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
        guard let documentPath = fileManager.urls(
            for: .documentDirectory,
            in: FileManager.SearchPathDomainMask.userDomainMask).first,
              let appSupportPath = fileManager.urls(
                for: .applicationSupportDirectory,
                in: FileManager.SearchPathDomainMask.userDomainMask).first
        else { return nil }

        switch directoryType {
        case .documents:
            return documentPath.appendingPathComponent("wallpapers")
        case .applicationSupport:
            return appSupportPath.appendingPathComponent("wallpapers")
        }
    }
}
