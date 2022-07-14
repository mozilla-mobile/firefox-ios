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

    static let testClientGuid = "abcdefghijkl"

    func testResetting() {
        let profile = MockBrowserProfile(localName: "testResetTests")

        // Add a client.
        let tabs = profile.peekTabs
        assertAddClient(tabs)

        // Replace remote device
        assertReplaceRemoteDevices(tabs)

        // Verify that it's there.
        assertClientsHaveGUIDsFromStorage(tabs, expected: [ResetTests.testClientGuid])

        // Tell the sync manager that "clients" has changed syncID.
        let engine = MockEngineStateChanges()
        engine.collections.append("clients")

        let error = profile.tabs.reopenIfClosed()
        if let error = error {
            XCTFail("Could not reopen tabs, failed with error \(error.description)")
            return
        }

        assertActionsOnEngine(profile: profile, engine: engine)

        assertNoClients(tabs)
    }
}

// MARK: - Helper methods
extension ResetTests {

    func assertAddClient(_ tabs: RemoteClientsAndTabs) {
        let addClientExpectation = expectation(description: "Add client fulfilled")
        tabs.insertOrUpdateClient(
            RemoteClient(guid: ResetTests.testClientGuid,
                         name: "Remote",
                         modified: Date.now(),
                         type: "mobile",
                         formfactor: "tablet",
                         os: "Windows",
                         version: "55.0.1a",
                         fxaDeviceId: "fxa1"))
        .uponQueue(.main) { result in
            XCTAssertTrue(result.isSuccess)
            addClientExpectation.fulfill()
        }

        wait(for: [addClientExpectation], timeout: 5.0)
    }

    func assertReplaceRemoteDevices(_ tabs: SQLiteRemoteClientsAndTabs) {
        let replaceRemoteExpectation = expectation(description: "Replace remote devices fulfilled")
        tabs.replaceRemoteDevices(
            [RemoteDevice(id: "fxa1",
                          name: "Device 1",
                          type: "desktop",
                          isCurrentDevice: false,
                          lastAccessTime: 123,
                          availableCommands: [:])])
        .uponQueue(.main) { result in
            XCTAssertTrue(result.isSuccess)
            replaceRemoteExpectation.fulfill()
        }

        wait(for: [replaceRemoteExpectation], timeout: 5.0)
    }

    func assertClientsHaveGUIDsFromStorage(_ storage: RemoteClientsAndTabs,
                                           expected: [GUID],
                                           file: StaticString = #file,
                                           line: UInt = #line) {

        let getClientExpectation = expectation(description: "Get client fulfilled")

        storage.getClients().uponQueue(.main) { result in
            let recs = result.successValue
            XCTAssertNotNil(recs, file: file, line: line)
            XCTAssertEqual(expected, recs!.map { $0.guid! }, file: file, line: line)
            getClientExpectation.fulfill()
        }

        wait(for: [getClientExpectation], timeout: 5.0)
    }

    func assertActionsOnEngine(profile: MockBrowserProfile, engine: MockEngineStateChanges) {
        let engineActionExpectation = expectation(description: "Action on engine fulfilled")

        profile.peekSyncManager.takeActionsOnEngineStateChanges(engine).uponQueue(.main) { result in
            XCTAssertTrue(result.isSuccess)

            // We threw away the command.
            XCTAssertEqual(engine.clearLocalCommandsCount, 1, "Clear local commands was called once")
            engineActionExpectation.fulfill()
        }

        wait(for: [engineActionExpectation], timeout: 5.0)
    }

    func assertNoClients(_ tabs: RemoteClientsAndTabs) {
        let getClientExpectation = expectation(description: "Get client fulfilled")

        // And now we have no local clients.
        tabs.getClients().uponQueue(.main) { result in
            let empty = result.successValue
            XCTAssertNotNil(empty)
            XCTAssertEqual(empty!, [])

            getClientExpectation.fulfill()
        }

        wait(for: [getClientExpectation], timeout: 5.0)
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
