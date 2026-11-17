// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

struct TabGroupSnapshot: Codable, Sendable {
    var groups: [TabGroup] = []
}

protocol TabGroupStorage: Sendable {
    func load() async throws -> TabGroupSnapshot
    func save(_ snapshot: TabGroupSnapshot) async throws
}

actor DefaultTabGroupStorage: TabGroupStorage {
    private enum Constants {
        static let currentVersion = 1
        static let fileName = "groups.json"
        static let backupFileName = "groups.backup.json"
    }

    enum StorageError: Error {
        case unsupportedVersion
    }

    private struct VersionHeader: Decodable {
        let version: Int
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
            if fileExists(at: primary) {
                return try decode(Data(contentsOf: primary))
            }
        } catch let error as StorageError {
            throw error
        } catch {
            guard fileExists(at: backup) else { throw error }
            return try decode(Data(contentsOf: backup))
        }
        guard fileExists(at: backup) else { return TabGroupSnapshot() }
        return try decode(Data(contentsOf: backup))
    }

    func save(_ snapshot: TabGroupSnapshot) throws {
        let primary = fileURL()
        let backup = fileURL(isBackup: true)
        var previous: Data?
        for url in [primary, backup] {
            guard fileExists(at: url) else { continue }
            let data = try Data(contentsOf: url)
            try checkVersion(data)
            if url == primary { previous = data }
        }

        let data = try JSONEncoder().encode(StoredSnapshot(version: Constants.currentVersion, snapshot: snapshot))
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        if let previous, (try? decode(previous)) != nil {
            try previous.write(to: backup, options: .atomic)
        }
        try data.write(to: primary, options: .atomic)
    }

    private func decode(_ data: Data) throws -> TabGroupSnapshot {
        try checkVersion(data)
        return try JSONDecoder().decode(StoredSnapshot.self, from: data).snapshot
    }

    private func checkVersion(_ data: Data) throws {
        guard let header = try? JSONDecoder().decode(VersionHeader.self, from: data) else { return }
        guard header.version == Constants.currentVersion else { throw StorageError.unsupportedVersion }
    }

    private func fileExists(at url: URL) -> Bool {
        if #available(iOS 16.0, *) {
            return fileManager.fileExists(atPath: url.path(percentEncoded: false))
        }
        return fileManager.fileExists(atPath: url.path)
    }

    private func fileURL(isBackup: Bool = false) -> URL {
        directory.appendingPathComponent(isBackup ? Constants.backupFileName : Constants.fileName)
    }
}
