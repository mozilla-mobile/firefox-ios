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
    func testNoClients() {
        let profile = MockBrowserProfile(localName: "testResetTests_noClient")
        assertNoClients(profile.peekTabs)
    }

    func testAddClient() {
        let profile = MockBrowserProfile(localName: "testResetTests_addClient")
        assertAddClient(tabs: profile.peekTabs)
    }

    func testReplaceRemoteDevices() {
        let profile = MockBrowserProfile(localName: "testResetTests_replaceRemote")
        // Replace remote device
        assertReplaceRemoteDevices(tabs: profile.peekTabs)
    }

    func testClientHaveGUIDsFromStorage() {
        let profile = MockBrowserProfile(localName: "testResetTests_haveGuids")
        assertAddClient(tabs: profile.peekTabs)
        assertReplaceRemoteDevices(tabs: profile.peekTabs)

        let getClientExpectation = expectation(description: "Get client fulfilled")

        // Verify that it's there.
        profile.peekTabs.getClients().uponQueue(.main) { result in
            let recs = result.successValue
            XCTAssertNotNil(recs)
            XCTAssertEqual([ResetTests.testClientGuid], recs!.map { $0.guid! })
            getClientExpectation.fulfill()
        }

        wait(for: [getClientExpectation], timeout: 5.0)
    }

    func testActionsOnEngine() throws {
        throw XCTSkip("testActionsOnEngine is unreliable on Bitrise, disabling")
//        let profile = MockBrowserProfile(localName: "testResetTests_actionsOnEngine")
//
//        // Tell the sync manager that "clients" has changed syncID.
//        let engine = MockEngineStateChanges()
//        engine.collections.append("clients")
//
//        let error = profile.tabs.reopenIfClosed()
//        if let error = error {
//            XCTFail("Could not reopen tabs, failed with error \(error.description)")
//            return
//        }
//
//        assertActionsOnEngine(profile: profile, engine: engine)
//
//        assertNoClients(profile.peekTabs)
    }
}

// MARK: - Helper methods
extension ResetTests {
    static let testClientGuid = "abcdefghijkl"

    static let testRemoteClient = RemoteClient(guid: ResetTests.testClientGuid,
                                               name: "Remote",
                                               modified: Date.now(),
                                               type: "mobile",
                                               formfactor: "tablet",
                                               os: "Windows",
                                               version: "55.0.1a",
                                               fxaDeviceId: "fxa1")

    func assertAddClient(tabs: SQLiteRemoteClientsAndTabs) {
        let addClientExpectation = expectation(description: "Add client fulfilled")
        tabs.insertOrUpdateClient(ResetTests.testRemoteClient)
        .uponQueue(.main) { result in
            XCTAssertTrue(result.isSuccess)
            XCTAssertEqual(result.successValue, 1, "One client was added")
            addClientExpectation.fulfill()
        }

        wait(for: [addClientExpectation], timeout: 5.0)
    }

    func assertReplaceRemoteDevices(tabs: SQLiteRemoteClientsAndTabs) {
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
