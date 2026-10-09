// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import TabDataStore
@testable import Client

final class TabGroupStorageTests: XCTestCase {
    private var directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)

    override func setUp() {
        super.setUp()
        directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: directory)
        super.tearDown()
    }

    private func snapshot(title: String = "Saved") -> TabGroupSnapshot {
        let tab = TabData(id: UUID(),
                          title: "Example",
                          siteUrl: "https://example.com",
                          faviconURL: nil,
                          isPrivate: false,
                          lastUsedTime: Date(),
                          createdAtTime: Date(),
                          temporaryDocumentSession: [:])
        return TabGroupSnapshot(groups: [TabGroup(title: title, color: .teal, tabIDs: [tab.id.uuidString])], tabs: [tab])
    }

    func testRoundTripKeepsMetadataOrderedIDsAndIndependentTabRecords() async throws {
        let expected = snapshot()
        try await DefaultTabGroupStorage(directory: directory).save(expected)
        let restored = try await DefaultTabGroupStorage(directory: directory).load()
        XCTAssertEqual(restored.groups, expected.groups)
        XCTAssertEqual(restored.tabs.first?.id, expected.tabs.first?.id)
        XCTAssertEqual(restored.tabs.first?.siteUrl, "https://example.com")
        let data = try Data(contentsOf: directory.appendingPathComponent("groups.json"))
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        XCTAssertNil(json["windowUUID"])
    }

    func testMissingStorageReturnsEmptyWithoutCreatingFiles() async throws {
        let result = try await DefaultTabGroupStorage(directory: directory).load()
        XCTAssertTrue(result.groups.isEmpty)
        XCTAssertTrue(result.tabs.isEmpty)
        XCTAssertFalse(FileManager.default.fileExists(atPath: directory.path))
    }

    func testProfilesHaveSeparateStorage() async throws {
        let first = directory.appendingPathComponent("first")
        let second = directory.appendingPathComponent("second")
        try await DefaultTabGroupStorage(directory: first).save(snapshot())
        let restored = try await DefaultTabGroupStorage(directory: second).load()
        XCTAssertTrue(restored.groups.isEmpty)
    }

    func testCorruptPrimaryUsesPreviousCompleteSnapshot() async throws {
        let store = DefaultTabGroupStorage(directory: directory)
        let first = snapshot(title: "First")
        try await store.save(first)
        try await store.save(snapshot(title: "Second"))
        try Data("broken".utf8).write(to: directory.appendingPathComponent("groups.json"))
        let restored = try await store.load()
        XCTAssertEqual(restored.groups, first.groups)
        XCTAssertEqual(restored.tabs.first?.id, first.tabs.first?.id)
        try await store.save(restored)
        let saved = try await store.load()
        XCTAssertEqual(saved.groups, first.groups)
    }

    func testCorruptPrimaryAndBackupThrow() async throws {
        let store = DefaultTabGroupStorage(directory: directory)
        try await store.save(snapshot())
        for name in ["groups.json", "groups.backup.json"] {
            try Data("broken".utf8).write(to: directory.appendingPathComponent(name))
        }
        do {
            _ = try await store.load()
            XCTFail("Expected decode failure")
        } catch {}
    }

    func testFutureVersionDoesNotFallBackToOlderBackup() async throws {
        let store = DefaultTabGroupStorage(directory: directory)
        try await store.save(snapshot())
        try await store.save(snapshot())
        let file = directory.appendingPathComponent("groups.json")
        var json = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: file)) as? [String: Any])
        json["version"] = 2
        try JSONSerialization.data(withJSONObject: json).write(to: file)
        do {
            _ = try await store.load()
            XCTFail("Expected unsupported version")
        } catch {
            XCTAssertTrue(error is DefaultTabGroupStorage.StorageError)
        }
    }

    func testExistingWindowAndSessionFilesRemainUntouched() async throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let window = directory.appendingPathComponent("window-data")
        let session = directory.appendingPathComponent("tab-session-data")
        let expected = Data("existing tab storage".utf8)
        try expected.write(to: window)
        try expected.write(to: session)
        try await DefaultTabGroupStorage(directory: directory.appendingPathComponent("tab-groups")).save(snapshot())
        XCTAssertEqual(try Data(contentsOf: window), expected)
        XCTAssertEqual(try Data(contentsOf: session), expected)
    }
}
