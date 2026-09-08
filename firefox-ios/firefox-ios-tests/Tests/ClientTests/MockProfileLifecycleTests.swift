// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import Storage
import Testing

@testable import Client

@Suite("MockProfile lifecycle")
struct MockProfileLifecycleTests {
    enum Database: CaseIterable {
        case readingList, places, tabs, logins, autofill, legacyBrowserDB

        func isUsable(in profile: MockProfile) async -> Bool {
            switch self {
            case .readingList:
                return await profile.readingList.getAvailableRecords().asyncValue.isSuccess
            case .places:
                return await profile.places.getRecentBookmarks(limit: 1).asyncValue.isSuccess
            case .tabs:
                return await profile.tabs.getAll().asyncValue.isSuccess
            case .logins:
                return await profile.logins.hasSyncedLogins().asyncValue.isSuccess
            case .autofill:
                return await withCheckedContinuation { continuation in
                    profile.autofill.listAllAddresses { _, error in
                        continuation.resume(returning: error == nil)
                    }
                }
            case .legacyBrowserDB:
                return await profile.pinnedSites.getPinnedTopSites().asyncValue.isSuccess
            }
        }
    }

    @Test("a database first touched after shutdown stays closed and writes nothing", arguments: Database.allCases)
    func touchedAfterShutdownStaysClosed(database: Database) async throws {
        try await withMockProfile { profile in
            profile.shutdown()
            let usable = await database.isUsable(in: profile)
            #expect(!usable)
            try #expect(databaseArtifacts(under: profile.files.rootPath).isEmpty)
        }
    }

    @Test("a database opens on first use and follows shutdown and reopen", arguments: Database.allCases)
    func followsLifecycle(database: Database) async throws {
        try await withMockProfile { profile in
            let usableOnFirstUse = await database.isUsable(in: profile)
            #expect(usableOnFirstUse)

            profile.shutdown()
            let usableAfterShutdown = await database.isUsable(in: profile)
            #expect(!usableAfterShutdown)

            profile.reopen()
            let usableAfterReopen = await database.isUsable(in: profile)
            #expect(usableAfterReopen)
        }
    }

    @Test("using Places creates its database")
    func usingPlacesCreatesDatabase() async throws {
        try await withMockProfile { profile in
            _ = profile.places
            try #expect(databaseArtifacts(under: profile.files.rootPath).contains("places.db"))
        }
    }

    @Test("a scoped profile's directory is removed when the scope ends")
    func scopedProfileRemovesDirectory() async throws {
        let root = try await withMockProfile { profile -> String in
            _ = profile.places
            #expect(FileManager.default.fileExists(atPath: profile.files.rootPath))
            return profile.files.rootPath
        }
        #expect(!FileManager.default.fileExists(atPath: root))
    }

    @Test("a released profile removes its directory")
    func releasedProfileRemovesDirectory() async {
        let root = autoreleasepool {
            let profile = MockProfile()
            _ = profile.places
            return profile.files.rootPath
        }
        #expect(await isEventuallyRemoved(root))
    }

    private func isEventuallyRemoved(_ path: String) async -> Bool {
        let deadline = Date().addingTimeInterval(1)
        while FileManager.default.fileExists(atPath: path), Date() < deadline {
            try? await Task<Never, Never>.sleep(nanoseconds: 10_000_000)
        }
        return !FileManager.default.fileExists(atPath: path)
    }

    /// A missing root means nothing was written; any other listing failure is a real error.
    private func databaseArtifacts(under root: String) throws -> [String] {
        guard FileManager.default.fileExists(atPath: root) else { return [] }
        return try FileManager.default.contentsOfDirectory(atPath: root)
            .filter { $0.hasSuffix(".db") || $0.hasSuffix(".db-wal") || $0.hasSuffix(".db-shm") }
            .sorted()
    }
}

private extension Deferred {
    var asyncValue: T {
        get async {
            await withCheckedContinuation { continuation in
                upon { continuation.resume(returning: $0) }
            }
        }
    }
}
