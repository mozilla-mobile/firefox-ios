/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

@testable import Client
import Shared
import Storage
import Sync
import UIKit

import XCTest

class MockBrowserProfile: BrowserProfile {
    var peekSyncManager: BrowserSyncManager {
        return self.syncManager as! BrowserSyncManager
    }

    var peekTabs: SQLiteRemoteClientsAndTabs {
        return self.remoteClientsAndTabs as! SQLiteRemoteClientsAndTabs
    }
}

class MockEngineStateChanges: EngineStateChanges {
    var collections: [String] = []
    var enabled: [String] = []
    var disabled: [String] = []
    var clearWasCalled: Bool = false

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
        clearWasCalled = true
    }
}

func assertClientsHaveGUIDs(fromStorage storage: RemoteClientsAndTabs, expected: [GUID]) {
    let recs = storage.getClients().value.successValue
    XCTAssertNotNil(recs)
    XCTAssertEqual(expected, recs!.map { $0.guid! })
}

class ResetTests: XCTestCase {
    func testResetting() {
        let profile = MockBrowserProfile(localName: "testResetTests")

        // Add a client.
        let tabs = profile.peekTabs
        XCTAssertTrue(tabs.insertOrUpdateClient(RemoteClient(guid: "abcdefghijkl", name: "Remote", modified: Date.now(), type: "mobile", formfactor: "tablet", os: "Windows")).value.isSuccess)

        // Verify that it's there.
        assertClientsHaveGUIDs(fromStorage: tabs, expected: ["abcdefghijkl"])

        // Tell the sync manager that "clients" has changed syncID.
        let e = MockEngineStateChanges()
        e.collections.append("clients")

        XCTAssertTrue(profile.peekSyncManager.takeActionsOnEngineStateChanges(e).value.isSuccess)

        // We threw away the command.
        XCTAssertTrue(e.clearWasCalled)

        // And now we have no local clients.
        let empty = tabs.getClients().value.successValue
        XCTAssertNotNil(empty)
        XCTAssertEqual(empty!, [])
    }
}
