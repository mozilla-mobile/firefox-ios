// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import TestKit
@testable import Client

@MainActor
final class TabGroupStorageTests: XCTestCase {
    private let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    private let unsupportedVersionData = Data(#"{"version":2,"snapshot":{"futureFormat":true}}"#.utf8)

    private var primaryURL: URL { directory.appendingPathComponent("groups.json") }
    private var backupURL: URL { directory.appendingPathComponent("groups.backup.json") }

    override func setUp() async throws {
        try await super.setUp()
    }

    override func tearDown() async throws {
        try? FileManager.default.removeItem(at: directory)
        try await super.tearDown()
    }

    func testSaveAndLoad_withGroup_preservesMetadataAndTabIDOrder() async throws {
        let expected = createSnapshot()
        try await createSubject().save(expected)

        let restored = try await createSubject().load()

        XCTAssertEqual(restored.groups, expected.groups)
        let data = try Data(contentsOf: primaryURL)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        let savedSnapshot = try XCTUnwrap(json["snapshot"] as? [String: Any])
        XCTAssertEqual(Set(savedSnapshot.keys), ["groups"])
        let savedGroups = try XCTUnwrap(savedSnapshot["groups"] as? [[String: Any]])
        let savedGroup = try XCTUnwrap(savedGroups.first)
        XCTAssertEqual(Set(savedGroup.keys), ["id", "title", "color", "icon", "tabIDs"])
        XCTAssertEqual(savedGroup["tabIDs"] as? [String], expected.groups.first?.tabIDs)
    }

    func testLoad_withVersionOneFixture_restoresMetadataAndOrderedTabIDs() async throws {
        let data = Data("""
        {
            "version": 1,
            "snapshot": {
                "groups": [{
                    "id": "00000000-0000-0000-0000-000000000001",
                    "title": "Saved group",
                    "color": {"light": {"red": 0.2, "green": 0.4, "blue": 0.6, "alpha": 0.8}},
                    "icon": {"sfSymbol": {"_0": "house.fill"}},
                    "tabIDs": ["00000000-0000-0000-0000-000000000002", "00000000-0000-0000-0000-000000000003"]
                }]
            }
        }
        """.utf8)
        let subject = createSubject()
        let expected = TabGroup(id: try XCTUnwrap(UUID(uuidString: "00000000-0000-0000-0000-000000000001")),
                                title: "Saved group",
                                color: CodableColor(red: 0.2, green: 0.4, blue: 0.6, alpha: 0.8),
                                icon: .sfSymbol("house.fill"),
                                tabIDs: ["00000000-0000-0000-0000-000000000002",
                                         "00000000-0000-0000-0000-000000000003"])
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try data.write(to: primaryURL)

        let result = try await subject.load()

        XCTAssertEqual(result.groups, [expected])
    }

    func testSaveAndLoad_withSpacesAndPercentSignsInDirectory_preservesSnapshot() async throws {
        let subject = createSubject(directory: directory.appendingPathComponent("Saved groups %"))
        let expected = createSnapshot()
        try await subject.save(expected)

        let restored = try await subject.load()

        XCTAssertEqual(restored.groups, expected.groups)
    }

    func testLoad_withoutFiles_returnsEmptySnapshotWithoutCreatingFiles() async throws {
        let result = try await createSubject().load()

        XCTAssertTrue(result.groups.isEmpty)
        XCTAssertFalse(FileManager.default.fileExists(atPath: directory.path))
    }

    func testLoad_withDifferentDirectory_returnsEmptySnapshot() async throws {
        let first = directory.appendingPathComponent("first")
        let second = directory.appendingPathComponent("second")
        try await createSubject(directory: first).save(createSnapshot())

        let restored = try await createSubject(directory: second).load()

        XCTAssertTrue(restored.groups.isEmpty)
    }

    func testSave_afterRecoveringCorruptPrimary_preservesBackup() async throws {
        let subject = createSubject()
        let first = createSnapshot(title: "First")
        try await subject.save(first)
        try await subject.save(createSnapshot(title: "Second"))
        let previousBackup = try Data(contentsOf: backupURL)
        try Data("broken".utf8).write(to: primaryURL)

        let restored = try await subject.load()
        XCTAssertEqual(restored.groups, first.groups)
        try await subject.save(restored)
        let saved = try await subject.load()

        XCTAssertEqual(saved.groups, first.groups)
        XCTAssertEqual(try Data(contentsOf: backupURL), previousBackup)
    }

    func testLoad_withCorruptPrimaryAndBackup_throwsDecodingError() async throws {
        let subject = createSubject()
        try await subject.save(createSnapshot())
        for url in [primaryURL, backupURL] {
            try Data("broken".utf8).write(to: url)
        }

        do {
            _ = try await subject.load()
            XCTFail("Expected decode failure")
        } catch {
            XCTAssertTrue(error is DecodingError)
        }
    }

    func testLoad_withUnsupportedPrimaryVersion_doesNotUseBackup() async throws {
        let subject = createSubject()
        try await subject.save(createSnapshot())
        try await subject.save(createSnapshot())
        try unsupportedVersionData.write(to: primaryURL)

        do {
            _ = try await subject.load()
            XCTFail("Expected unsupported version")
        } catch {
            XCTAssertEqual(error as? DefaultTabGroupStorage.StorageError, .unsupportedVersion)
        }
    }

    func testLoad_withCorruptPrimaryAndUnsupportedBackupVersion_throwsUnsupportedVersion() async throws {
        let subject = createSubject()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try Data("broken".utf8).write(to: primaryURL)
        try unsupportedVersionData.write(to: backupURL)

        do {
            _ = try await subject.load()
            XCTFail("Expected unsupported version")
        } catch {
            XCTAssertEqual(error as? DefaultTabGroupStorage.StorageError, .unsupportedVersion)
        }
    }

    func testLoad_withoutPrimary_loadsBackup() async throws {
        let subject = createSubject()
        let first = createSnapshot(title: "First")
        try await subject.save(first)
        try await subject.save(createSnapshot(title: "Second"))
        try FileManager.default.removeItem(at: primaryURL)

        let restored = try await subject.load()

        XCTAssertEqual(restored.groups, first.groups)
    }

    func testLoad_withCorruptPrimaryWithoutBackup_throwsDecodingError() async throws {
        let subject = createSubject()
        try await subject.save(createSnapshot())
        try Data("broken".utf8).write(to: primaryURL)

        do {
            _ = try await subject.load()
            XCTFail("Expected decode failure")
        } catch {
            XCTAssertTrue(error is DecodingError)
        }
    }

    func testSave_withUnsupportedPrimaryVersion_throwsWithoutChangingFiles() async throws {
        let subject = createSubject()
        try await subject.save(createSnapshot(title: "First"))
        try await subject.save(createSnapshot(title: "Second"))
        let previousBackup = try Data(contentsOf: backupURL)
        try unsupportedVersionData.write(to: primaryURL)

        do {
            try await subject.save(createSnapshot(title: "Replacement"))
            XCTFail("Expected unsupported version")
        } catch {
            XCTAssertEqual(error as? DefaultTabGroupStorage.StorageError, .unsupportedVersion)
        }

        XCTAssertEqual(try Data(contentsOf: primaryURL), unsupportedVersionData)
        XCTAssertEqual(try Data(contentsOf: backupURL), previousBackup)
    }

    func testSave_withUnsupportedBackupVersion_throwsWithoutChangingFiles() async throws {
        let subject = createSubject()
        try await subject.save(createSnapshot())
        let previousPrimary = try Data(contentsOf: primaryURL)
        try unsupportedVersionData.write(to: backupURL)

        do {
            try await subject.save(createSnapshot(title: "Replacement"))
            XCTFail("Expected unsupported version")
        } catch {
            XCTAssertEqual(error as? DefaultTabGroupStorage.StorageError, .unsupportedVersion)
        }

        XCTAssertEqual(try Data(contentsOf: primaryURL), previousPrimary)
        XCTAssertEqual(try Data(contentsOf: backupURL), unsupportedVersionData)
    }

    func testSave_withUnsupportedBackupAndMissingPrimary_doesNotCreatePrimary() async throws {
        let subject = createSubject()
        try await subject.save(createSnapshot())
        try FileManager.default.removeItem(at: primaryURL)
        try unsupportedVersionData.write(to: backupURL)

        do {
            try await subject.save(createSnapshot(title: "Replacement"))
            XCTFail("Expected unsupported version")
        } catch {
            XCTAssertEqual(error as? DefaultTabGroupStorage.StorageError, .unsupportedVersion)
        }

        XCTAssertFalse(FileManager.default.fileExists(atPath: primaryURL.path))
        XCTAssertEqual(try Data(contentsOf: backupURL), unsupportedVersionData)
    }

    func testSave_withSiblingFiles_leavesThemUnchanged() async throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let window = directory.appendingPathComponent("window-data")
        let session = directory.appendingPathComponent("tab-session-data")
        let expected = Data("existing tab storage".utf8)
        try expected.write(to: window)
        try expected.write(to: session)

        try await createSubject(directory: directory.appendingPathComponent("tab-groups")).save(createSnapshot())

        XCTAssertEqual(try Data(contentsOf: window), expected)
        XCTAssertEqual(try Data(contentsOf: session), expected)
    }

    private func createSubject(directory: URL? = nil,
                               file: StaticString = #filePath,
                               line: UInt = #line) -> DefaultTabGroupStorage {
        let subject = DefaultTabGroupStorage(directory: directory ?? self.directory)
        trackForMemoryLeaks(subject, file: file, line: line)
        return subject
    }

    private func createSnapshot(title: String = "Saved") -> TabGroupSnapshot {
        let color = CodableColor(red: 0.17, green: 0.43, blue: 0.71, alpha: 0.65)
        let group = TabGroup(title: title,
                             color: color,
                             icon: .sfSymbol("graduationcap.fill"),
                             tabIDs: [UUID().uuidString, UUID().uuidString])
        return TabGroupSnapshot(groups: [group])
    }
}
