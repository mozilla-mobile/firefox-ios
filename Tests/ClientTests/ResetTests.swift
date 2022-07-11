// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

@testable import Client
import Shared
@testable import Storage
import Sync
import UIKit

import XCTest

class ResetTests: XCTestCase {
    func testResetting() {
        let profile = MockBrowserProfile(localName: "testResetTests")

        // Add a client.
        let tabs = profile.peekTabs
        XCTAssertTrue(tabs.insertOrUpdateClient(
            RemoteClient(guid: "abcdefghijkl",
                         name: "Remote",
                         modified: Date.now(),
                         type: "mobile",
                         formfactor: "tablet",
                         os: "Windows",
                         version: "55.0.1a",
                         fxaDeviceId: "fxa1")).value.isSuccess)
        tabs.replaceRemoteDevices([RemoteDevice(id: "fxa1",
                                                name: "Device 1",
                                                type: "desktop",
                                                isCurrentDevice: false,
                                                lastAccessTime: 123,
                                                availableCommands: [:])]).succeeded()

        // Verify that it's there.
        assertClientsHaveGUIDsFromStorage(tabs, expected: ["abcdefghijkl"])

        // Tell the sync manager that "clients" has changed syncID.
        let engine = MockEngineStateChanges()
        engine.collections.append("clients")

        let error = profile.tabs.reopenIfClosed()
        if let error = error {
            XCTFail("Could not reopen tabs, failed with error \(error.description)")
            return
        }

        XCTAssertTrue(profile.peekSyncManager.takeActionsOnEngineStateChanges(engine).value.isSuccess)

        // We threw away the command.
        XCTAssertEqual(engine.clearLocalCommandsCount, 1, "Clear local commands was called once")

        // And now we have no local clients.
        let empty = tabs.getClients().value.successValue
        XCTAssertNotNil(empty)
        XCTAssertEqual(empty!, [])
    }
}

// MARK: - Helper methods
extension ResetTests {
    func assertClientsHaveGUIDsFromStorage(_ storage: RemoteClientsAndTabs, expected: [GUID]) {
        let recs = storage.getClients().value.successValue
        XCTAssertNotNil(recs)
        XCTAssertEqual(expected, recs!.map { $0.guid! })
    }
}

// MARK: - MockBrowserProfile
class MockBrowserProfile: BrowserProfile {
    var peekSyncManager: BrowserSyncManager {
        return self.syncManager as! BrowserSyncManager
    }

    var peekTabs: SQLiteRemoteClientsAndTabs {
        return self.remoteClientsAndTabs as! SQLiteRemoteClientsAndTabs
    }
}

// MARK: - MockEngineStateChanges
class MockEngineStateChanges: EngineStateChanges {
    var collections: [String] = []
    var enabled: [String] = []
    var disabled: [String] = []
    var clearLocalCommandsCount = 0

    func collectionsThatNeedLocalReset() -> [String] {
        return self.collections
    }

    func enginesEnabled() -> [String] {
        return self.enabled
    }

    func enginesDisabled() -> [String] {
        return self.disabled
    }

    func clearLocalCommands() {
        clearLocalCommandsCount += 1
    }
}
