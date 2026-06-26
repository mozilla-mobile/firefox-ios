// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Shared
import XCTest

@testable import Client

final class AdsClientDocumentsDirectoryMigrationTests: XCTestCase {
    private var fileManager: MockAdsClientMigrationFileManager!
    private var userDefaults: MockUserDefaults!

    override func setUp() {
        super.setUp()
        fileManager = MockAdsClientMigrationFileManager()
        userDefaults = MockUserDefaults()
    }

    override func tearDown() {
        fileManager = nil
        userDefaults = nil
        super.tearDown()
    }

    func testRemoveLegacyDatabaseFiles_whenFilesExist_removesDatabasesAndSidecarFilesAndMarksMigrationComplete() {
        fileManager.existingPaths = [
            "/Documents/ads-client.db",
            "/Documents/ads-client.db-shm",
            "/Documents/ads-client.db-wal",
            "/Documents/ads-client.db-journal",
            "/Documents/ads-client-staging.db",
            "/Documents/ads-client-staging.db-shm",
            "/Documents/ads-client-staging.db-wal",
            "/Documents/ads-client-staging.db-journal"
        ]
        let subject = createSubject()

        subject.removeLegacyDatabaseFiles()

        XCTAssertEqual(
            fileManager.removedURLs.map(\.path),
            [
                "/Documents/ads-client.db",
                "/Documents/ads-client.db-shm",
                "/Documents/ads-client.db-wal",
                "/Documents/ads-client.db-journal",
                "/Documents/ads-client-staging.db",
                "/Documents/ads-client-staging.db-shm",
                "/Documents/ads-client-staging.db-wal",
                "/Documents/ads-client-staging.db-journal"
            ]
        )
        XCTAssertTrue(userDefaults.bool(forKey: PrefsKeys.AdsClient.documentsDirectoryMigrationCheck))
    }

    func testRemoveLegacyDatabaseFiles_whenFilesDoNotExist_marksMigrationComplete() {
        let subject = createSubject()

        subject.removeLegacyDatabaseFiles()

        XCTAssertTrue(fileManager.removedURLs.isEmpty)
        XCTAssertTrue(userDefaults.bool(forKey: PrefsKeys.AdsClient.documentsDirectoryMigrationCheck))
    }

    func testRemoveLegacyDatabaseFiles_whenMigrationAlreadyComplete_doesNotCheckDocumentsDirectory() {
        userDefaults.set(true, forKey: PrefsKeys.AdsClient.documentsDirectoryMigrationCheck)
        let subject = createSubject()

        subject.removeLegacyDatabaseFiles()

        XCTAssertEqual(fileManager.urlsForDirectoryCalled, 0)
        XCTAssertTrue(fileManager.removedURLs.isEmpty)
    }

    func testRemoveLegacyDatabaseFiles_whenRemoveFails_doesNotMarkMigrationComplete() {
        fileManager.existingPaths = ["/Documents/ads-client.db"]
        fileManager.removeError = CocoaError(.fileWriteUnknown)
        let subject = createSubject()

        subject.removeLegacyDatabaseFiles()

        XCTAssertEqual(fileManager.removedURLs.map(\.path), ["/Documents/ads-client.db"])
        XCTAssertFalse(userDefaults.bool(forKey: PrefsKeys.AdsClient.documentsDirectoryMigrationCheck))
    }

    private func createSubject() -> AdsClientDocumentsDirectoryMigration {
        return AdsClientDocumentsDirectoryMigration(
            fileManager: fileManager,
            userDefaults: userDefaults
        )
    }
}

private final class MockAdsClientMigrationFileManager: FileManagerProtocol, @unchecked Sendable {
    var existingPaths: Set<String> = []
    var removeError: Error?
    var removedURLs: [URL] = []
    var urlsForDirectoryCalled = 0

    func fileExists(atPath path: String) -> Bool {
        return existingPaths.contains(path)
    }

    func urls(for directory: FileManager.SearchPathDirectory,
              in domainMask: FileManager.SearchPathDomainMask) -> [URL] {
        urlsForDirectoryCalled += 1
        return [URL(fileURLWithPath: "/Documents")]
    }

    func contentsOfDirectory(atPath path: String) throws -> [String] {
        return []
    }

    func moveItem(at: URL, to: URL) throws {}

    func removeItem(atPath path: String) throws {}

    func removeItem(at url: URL) throws {
        removedURLs.append(url)

        if let removeError {
            throw removeError
        }
    }

    func copyItem(at srcURL: URL, to dstURL: URL) throws {}

    func createDirectory(
        atPath path: String,
        withIntermediateDirectories createIntermediates: Bool,
        attributes: [FileAttributeKey: Any]?
    ) throws {}

    func contentsOfDirectoryAtPath(_ path: String, withFilenamePrefix prefix: String) throws -> [String] {
        return []
    }

    func contents(atPath path: String) -> Data? {
        return nil
    }

    func contentsOfDirectory(
        at url: URL,
        includingPropertiesForKeys keys: [URLResourceKey]?,
        options mask: FileManager.DirectoryEnumerationOptions
    ) throws -> [URL] {
        return []
    }

    func createFile(
        atPath path: String,
        contents data: Data?,
        attributes attr: [FileAttributeKey: Any]?
    ) -> Bool {
        return true
    }
}
