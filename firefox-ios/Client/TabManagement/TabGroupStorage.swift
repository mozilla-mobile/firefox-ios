// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import TabDataStore

struct TabGroupSnapshot: Codable, Sendable {
    var groups: [TabGroup] = []
    var tabs: [TabData] = []
}

protocol TabGroupStorage: Sendable {
    func load() async throws -> TabGroupSnapshot
    func save(_ snapshot: TabGroupSnapshot) async throws
}

actor DefaultTabGroupStorage: TabGroupStorage {
    enum StorageError: Error {
        case unsupportedVersion
    }

    private struct StoredSnapshot: Codable {
        let version: Int
        let snapshot: TabGroupSnapshot
    }

    private let directory: URL
    private let fileManager: FileManager

    init(directory: URL, fileManager: FileManager = .default) {
        self.directory = directory
        self.fileManager = fileManager
    }

    func load() throws -> TabGroupSnapshot {
        let primary = fileURL()
        let backup = fileURL(isBackup: true)
        do {
            if fileManager.fileExists(atPath: primary.path) {
                return try decode(Data(contentsOf: primary))
            }
        } catch let error as StorageError {
            throw error
        } catch {
            guard fileManager.fileExists(atPath: backup.path) else { throw error }
            return try decode(Data(contentsOf: backup))
        }
        guard fileManager.fileExists(atPath: backup.path) else { return TabGroupSnapshot() }
        return try decode(Data(contentsOf: backup))
    }

    func save(_ snapshot: TabGroupSnapshot) throws {
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        let primary = fileURL()
        let data = try JSONEncoder().encode(StoredSnapshot(version: 1, snapshot: snapshot))
        if let previous = try? Data(contentsOf: primary), (try? decode(previous)) != nil {
            try previous.write(to: fileURL(isBackup: true), options: .atomic)
        }
        try data.write(to: primary, options: .atomic)
    }

    private func decode(_ data: Data) throws -> TabGroupSnapshot {
        let stored = try JSONDecoder().decode(StoredSnapshot.self, from: data)
        guard stored.version == 1 else { throw StorageError.unsupportedVersion }
        return stored.snapshot
    }

    private func fileURL(isBackup: Bool = false) -> URL {
        directory.appendingPathComponent(isBackup ? "groups.backup.json" : "groups.json")
    }
}
