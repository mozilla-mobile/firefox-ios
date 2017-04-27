/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Deferred
import Foundation
import Shared
@testable import Storage
@testable import Sync
import SwiftyJSON

import XCTest

class TestBookmarksRepairRequestor: XCTestCase {
    func testNoClients() {
        let expectation = self.expectation(description: #function)

        let prefs = MockProfilePrefs()
        let scratchpad = Scratchpad(b: KeyBundle.random(), persistingTo: prefs)
        let localClient = RemoteClient(guid: nil, name: "Test local client", modified: (Date.now() - OneMinuteInMilliseconds), type: "mobile", formfactor: "largetablet", os: "iOS", version: nil)
        let remoteClients = MockRemoteClientsAndTabs([ClientAndTabs(client: localClient, tabs: [])])
        let validationInfo = [(type: "missingvalues", ids: ["mock-guid1", "mock-guid2"])]

        let requestor = BookmarksRepairRequestor(scratchpad: scratchpad, basePrefs: prefs, remoteClients: remoteClients)
        requestor.startRepairs(validationInfo: validationInfo) >>== { result in
            XCTAssertTrue(result)
            XCTAssertEqual(remoteClients.commands.count, 1)
            XCTAssertEqual(remoteClients.commands["localID"]!.count, 0)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10, handler: nil)
    }

    func testOneClientNoResponse() {
        let expectation = self.expectation(description: #function)

        let prefs = MockProfilePrefs()
        let scratchpad = Scratchpad(b: KeyBundle.random(), persistingTo: prefs)
        let localClient = RemoteClient(guid: nil, name: "Test local client", modified: (Date.now() - OneMinuteInMilliseconds), type: "mobile", formfactor: "largetablet", os: "iOS", version: nil)
        let remoteClient = RemoteClient(guid: "client-a", name: "Test remote client", modified: (Date.now() - OneMinuteInMilliseconds), type: "desktop", formfactor: nil, os: nil, version: "55.0.1")
        let remoteClients = MockRemoteClientsAndTabs([ClientAndTabs(client: localClient, tabs: []), ClientAndTabs(client: remoteClient, tabs: [])])
        let validationInfo = [(type: "missingvalues", ids: ["mock-guid1", "mock-guid2"])]

        let requestor = BookmarksRepairRequestor(scratchpad: scratchpad, basePrefs: prefs, remoteClients: remoteClients)
        requestor.startRepairs(validationInfo: validationInfo) >>== { result -> Deferred<Maybe<Bool>> in
            XCTAssertTrue(result)
            XCTAssertEqual(prefs.stringForKey("repairs.bookmark.state"), "repair.sent")
            checkOutgoingCommand(remoteClients: remoteClients, clientID: "client-a")
            // asking it to continue stays in that state until we timeout or the command
            // is removed.
            return requestor.continueRepairs()
            } >>== { result -> Deferred<Maybe<Bool>> in
                XCTAssertTrue(result)
                XCTAssertEqual(prefs.stringForKey("repairs.bookmark.state"), "repair.sent")

                // now pretend that client synced.
                remoteClients.deleteCommands("client-a")
                return requestor.continueRepairs()
            } >>== { result -> Deferred<Maybe<Bool>> in
                XCTAssertTrue(result)
                XCTAssertEqual(prefs.stringForKey("repairs.bookmark.state"), "repair.sent-again")
                // the command should be outgoing again.
                checkOutgoingCommand(remoteClients: remoteClients, clientID: "client-a")

                // pretend that client synced again without writing a command.
                remoteClients.deleteCommands("client-a")
                return requestor.continueRepairs()
            } >>== { result in
                XCTAssertTrue(result)
                XCTAssertEqual(prefs.stringForKey("repairs.bookmark.state"), nil)
                expectation.fulfill()
        }
        waitForExpectations(timeout: 10, handler: nil)
    }

    func testOneClientTimeout() {
        let expectation = self.expectation(description: #function)

        let prefs = MockProfilePrefs()
        let scratchpad = Scratchpad(b: KeyBundle.random(), persistingTo: prefs)
        let localClient = RemoteClient(guid: nil, name: "Test local client", modified: (Date.now() - OneMinuteInMilliseconds), type: "mobile", formfactor: "largetablet", os: "iOS", version: nil)
        let remoteClient = RemoteClient(guid: "client-a", name: "Test remote client", modified: (Date.now() - OneMinuteInMilliseconds), type: "desktop", formfactor: nil, os: nil, version: "55.0.1")
        let remoteClients = MockRemoteClientsAndTabs([ClientAndTabs(client: localClient, tabs: []), ClientAndTabs(client: remoteClient, tabs: [])])
        let validationInfo = [(type: "missingvalues", ids: ["mock-guid1", "mock-guid2"])]

        let requestor = BookmarksRepairRequestor(scratchpad: scratchpad, basePrefs: prefs, remoteClients: remoteClients)
        requestor.startRepairs(validationInfo: validationInfo) >>== { result -> Deferred<Maybe<Bool>> in
            XCTAssertTrue(result)
            XCTAssertEqual(prefs.stringForKey("repairs.bookmark.state"), "repair.sent")
            checkOutgoingCommand(remoteClients: remoteClients, clientID: "client-a")
            // pretend we are now in the future (well actually, that the request was made a long time ago)
            prefs.setTimestamp(0, forKey: "repairs.bookmark.when")
            return requestor.continueRepairs()
            } >>== { result in
                // We should be finished as we gave up in disgust.
                XCTAssertTrue(result)
                XCTAssertEqual(prefs.stringForKey("repairs.bookmark.state"), nil)
                expectation.fulfill()
        }
        waitForExpectations(timeout: 10, handler: nil)
    }

    func testLatestClientUsed() {
        let expectation = self.expectation(description: #function)

        let prefs = MockProfilePrefs()
        let scratchpad = Scratchpad(b: KeyBundle.random(), persistingTo: prefs)
        let localClient = RemoteClient(guid: nil, name: "Test local client", modified: (Date.now() - OneMinuteInMilliseconds), type: "mobile", formfactor: "largetablet", os: "iOS", version: nil)
        let clientEarly = RemoteClient(guid: "client-early", name: "Test remote client", modified: (Date.now() - OneWeekInMilliseconds), type: "desktop", formfactor: nil, os: nil, version: "55.0.1")
        let clientLate = RemoteClient(guid: "client-late", name: "Test remote client", modified: (Date.now() - OneMinuteInMilliseconds), type: "desktop", formfactor: nil, os: nil, version: "55.0.1")
        let remoteClients = MockRemoteClientsAndTabs([ClientAndTabs(client: localClient, tabs: []), ClientAndTabs(client: clientEarly, tabs: []), ClientAndTabs(client: clientLate, tabs: [])])
        let validationInfo = [(type: "missingvalues", ids: ["mock-guid1", "mock-guid2"])]

        let requestor = BookmarksRepairRequestor(scratchpad: scratchpad, basePrefs: prefs, remoteClients: remoteClients)
        requestor.startRepairs(validationInfo: validationInfo) >>== { result in
            XCTAssertTrue(result)
            XCTAssertEqual(prefs.stringForKey("repairs.bookmark.state"), "repair.sent")
            // the repair command should be outgoing to the most-recent client.
            checkOutgoingCommand(remoteClients: remoteClients, clientID: "client-late")
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10, handler: nil)
    }

    func testClientVanishes() {
        let expectation = self.expectation(description: #function)

        let prefs = MockProfilePrefs()
        let scratchpad = Scratchpad(b: KeyBundle.random(), persistingTo: prefs)
        let localClient = RemoteClient(guid: nil, name: "Test local client", modified: (Date.now() - OneMinuteInMilliseconds), type: "mobile", formfactor: "largetablet", os: "iOS", version: nil)
        let remoteClientA = RemoteClient(guid: "client-a", name: "Test remote client", modified: Date.now(), type: "desktop", formfactor: nil, os: nil, version: "55.0.1")
        let remoteClientB = RemoteClient(guid: "client-b", name: "Test remote client", modified: (Date.now() - OneMinuteInMilliseconds), type: "desktop", formfactor: nil, os: nil, version: "55.0.1")
        let remoteClients = MockRemoteClientsAndTabs([ClientAndTabs(client: remoteClientA, tabs: []), ClientAndTabs(client: localClient, tabs: []), ClientAndTabs(client: remoteClientB, tabs: [])])
        let validationInfo = [(type: "missingvalues", ids: ["mock-guid1", "mock-guid2"])]
        let flowID = Bytes.generateGUID()

        let requestor = BookmarksRepairRequestor(scratchpad: scratchpad, basePrefs: prefs, remoteClients: remoteClients)
        requestor.startRepairs(validationInfo: validationInfo, flowID: flowID) >>== { result -> Deferred<Maybe<Bool>> in
            XCTAssertTrue(result)
            XCTAssertEqual(prefs.stringForKey("repairs.bookmark.state"), "repair.sent")
            checkOutgoingCommand(remoteClients: remoteClients, clientID: "client-a")
            // asking it to continue stays in that state until we timeout or the command
            // is removed.
            return requestor.continueRepairs()
            } >>== { result -> Deferred<Maybe<Bool>> in
                XCTAssertTrue(result)
                XCTAssertEqual(prefs.stringForKey("repairs.bookmark.state"), "repair.sent")
                // the command should now be outgoing.
                checkOutgoingCommand(remoteClients: remoteClients, clientID: "client-a")

                remoteClients.deleteCommands("client-a")
                // Now let's pretend the client vanished.
                remoteClients.clientsAndTabs.removeFirst()
                return requestor.continueRepairs()
            } >>== { result -> Deferred<Maybe<Bool>> in
                XCTAssertTrue(result)
                XCTAssertEqual(prefs.stringForKey("repairs.bookmark.state"), "repair.sent")
                // We should have moved on to client-b.
                checkOutgoingCommand(remoteClients: remoteClients, clientID: "client-b")

                // Now let's pretend client B wrote all missing IDs.
                let repairResponse = RepairResponse(collection: "bookmarks", request: "upload", flowID: flowID, clientID: "client-b", ids: ["mock-guid1", "mock-guid2"])
                return requestor.continueRepairs(response: repairResponse)
            } >>== { result in
                XCTAssertTrue(result)
                // We should be finished as we got all our IDs.
                XCTAssertEqual(prefs.stringForKey("repairs.bookmark.state"), nil)
                expectation.fulfill()
        }
        waitForExpectations(timeout: 10, handler: nil)
    }

    func testMultiClients() {
        let expectation = self.expectation(description: #function)

        let prefs = MockProfilePrefs()
        let scratchpad = Scratchpad(b: KeyBundle.random(), persistingTo: prefs)
        let localClient = RemoteClient(guid: nil, name: "Test local client", modified: (Date.now() - OneMinuteInMilliseconds), type: "mobile", formfactor: "largetablet", os: "iOS", version: nil)
        let remoteClientA = RemoteClient(guid: "client-a", name: "Test remote client", modified: Date.now(), type: "desktop", formfactor: nil, os: nil, version: "55.0.1")
        let remoteClientB = RemoteClient(guid: "client-b", name: "Test remote client", modified: (Date.now() - OneMinuteInMilliseconds), type: "desktop", formfactor: nil, os: nil, version: "55.0.1")
        let remoteClients = MockRemoteClientsAndTabs([ClientAndTabs(client: remoteClientA, tabs: []), ClientAndTabs(client: localClient, tabs: []), ClientAndTabs(client: remoteClientB, tabs: [])])
        let validationInfo = [(type: "missingvalues", ids: ["mock-guid1", "mock-guid2", "mock-guid3"])]
        let flowID = Bytes.generateGUID()

        let requestor = BookmarksRepairRequestor(scratchpad: scratchpad, basePrefs: prefs, remoteClients: remoteClients)
        requestor.startRepairs(validationInfo: validationInfo, flowID: flowID) >>== { result -> Deferred<Maybe<Bool>> in
            XCTAssertTrue(result)
            XCTAssertEqual(prefs.stringForKey("repairs.bookmark.state"), "repair.sent")
            checkOutgoingCommand(remoteClients: remoteClients, clientID: "client-a")
            // asking it to continue stays in that state until we timeout or the command
            // is removed.
            return requestor.continueRepairs()
            } >>== { result -> Deferred<Maybe<Bool>> in
                XCTAssertTrue(result)
                XCTAssertEqual(prefs.stringForKey("repairs.bookmark.state"), "repair.sent")
                // the command should now be outgoing.
                checkOutgoingCommand(remoteClients: remoteClients, clientID: "client-a")

                remoteClients.deleteCommands("client-a")
                // Now let's pretend the client wrote a response.
                let repairResponse = RepairResponse(collection: "bookmarks", request: "upload", flowID: flowID, clientID: "client-a", ids: ["mock-guid1", "mock-guid2"])
                return requestor.continueRepairs(response: repairResponse)
            } >>== { result -> Deferred<Maybe<Bool>> in
                XCTAssertTrue(result)
                XCTAssertEqual(prefs.stringForKey("repairs.bookmark.state"), "repair.sent")
                // We should have moved on to client-b.
                checkOutgoingCommand(remoteClients: remoteClients, clientID: "client-b")

                remoteClients.deleteCommands("client-b")
                // Now let's pretend client B write the missing ID.
                let repairResponse = RepairResponse(collection: "bookmarks", request: "upload", flowID: flowID, clientID: "client-b", ids: ["mock-guid3"])
                return requestor.continueRepairs(response: repairResponse)
            } >>== { result in
                XCTAssertTrue(result)
                // We should be finished as we got all our IDs.
                XCTAssertEqual(prefs.stringForKey("repairs.bookmark.state"), nil)
                expectation.fulfill()
        }
        waitForExpectations(timeout: 10, handler: nil)
    }

    func testAlreadyRepairingContinue() {
        let expectation = self.expectation(description: #function)

        let prefs = MockProfilePrefs()
        let scratchpad = Scratchpad(b: KeyBundle.random(), persistingTo: prefs)
        let localClient = RemoteClient(guid: nil, name: "Test local client", modified: (Date.now() - OneMinuteInMilliseconds), type: "mobile", formfactor: "largetablet", os: "iOS", version: nil)
        let remoteClientA = RemoteClient(guid: "client-a", name: "Test remote client", modified: Date.now(), type: "desktop", formfactor: nil, os: nil, version: "55.0.1")
        let remoteClientB = RemoteClient(guid: "client-b", name: "Test remote client", modified: (Date.now() - OneMinuteInMilliseconds), type: "desktop", formfactor: nil, os: nil, version: "55.0.1")
        let remoteClients = MockRemoteClientsAndTabs([ClientAndTabs(client: remoteClientA, tabs: []), ClientAndTabs(client: localClient, tabs: []), ClientAndTabs(client: remoteClientB, tabs: [])])
        let validationInfo = [(type: "missingvalues", ids: ["mock-guid1", "mock-guid2", "mock-guid3"])]
        let flowID = Bytes.generateGUID()

        let requestor = BookmarksRepairRequestor(scratchpad: scratchpad, basePrefs: prefs, remoteClients: remoteClients)
        requestor.startRepairs(validationInfo: validationInfo, flowID: flowID) >>== { result -> Deferred<Maybe<Bool>> in
            XCTAssertTrue(result)
            XCTAssertEqual(prefs.stringForKey("repairs.bookmark.state"), "repair.sent")
            checkOutgoingCommand(remoteClients: remoteClients, clientID: "client-a")
            // asking it to continue stays in that state until we timeout or the command
            // is removed.
            return requestor.continueRepairs()
            } >>== { result -> Deferred<Maybe<Bool>> in
                XCTAssertTrue(result)
                XCTAssertEqual(prefs.stringForKey("repairs.bookmark.state"), "repair.sent")
                // the command should now be outgoing.
                checkOutgoingCommand(remoteClients: remoteClients, clientID: "client-a")

                remoteClients.deleteCommands("client-a")
                // Now let's pretend the client wrote a response (it doesn't matter what's in here)
                let repairResponse = RepairResponse(collection: "bookmarks", request: "upload", flowID: flowID, clientID: "client-a", ids: ["mock-guid1", "mock-guid2"])

                // and another client also started a request
                let otherRequest = RepairRequest(collection: "bookmarks", request: "upload", flowID: "abdc", requestor: "client-c", ids: ["bogusid"])
                remoteClients.insertCommand(otherRequest.toSyncCommand(), forClients: [remoteClientB])

                return requestor.continueRepairs(response: repairResponse)
            } >>== { result in
                XCTAssertTrue(result)

                // We should have aborted now
                XCTAssertEqual(prefs.stringForKey("repairs.bookmark.state"), nil)
                expectation.fulfill()
        }
        waitForExpectations(timeout: 10, handler: nil)
    }
}

func checkOutgoingCommand(remoteClients: MockRemoteClientsAndTabs, clientID: GUID) {
    let outgoingCmds = remoteClients.commands[clientID]!
    XCTAssertEqual(outgoingCmds.count, 1)
    XCTAssertEqual(JSON.parse(outgoingCmds.first!.value)["command"].stringValue, "repairRequest")
}

open class MockRemoteClientsAndTabs: RemoteClientsAndTabs {
    open var clientsAndTabs: [ClientAndTabs]
    open var commands: [GUID: [SyncCommand]]

    public init(_ clientsAndTabs: [ClientAndTabs]) {
        self.clientsAndTabs = clientsAndTabs
        self.commands = clientsAndTabs.map { $0.client.guid ?? "localID" }.reduce([String: [SyncCommand]]()) { (dict, clientId) -> [String: [SyncCommand]] in
            var dict = dict
            dict[clientId] = [SyncCommand]()
            return dict
        }
    }

    open func onRemovedAccount() -> Success {
        return succeed()
    }

    open func wipeClients() -> Success {
        return succeed()
    }

    open func wipeRemoteTabs() -> Deferred<Maybe<()>> {
        return succeed()
    }

    open func wipeTabs() -> Success {
        return succeed()
    }

    open func insertOrUpdateClients(_ clients: [RemoteClient]) -> Deferred<Maybe<Int>> {
        return deferMaybe(0)
    }

    open func insertOrUpdateClient(_ client: RemoteClient) -> Deferred<Maybe<Int>> {
        return deferMaybe(0)
    }

    open func insertOrUpdateTabs(_ tabs: [RemoteTab]) -> Deferred<Maybe<Int>> {
        return insertOrUpdateTabsForClientGUID(nil, tabs: [RemoteTab]())
    }

    open func insertOrUpdateTabsForClientGUID(_ clientGUID: String?, tabs: [RemoteTab]) -> Deferred<Maybe<Int>> {
        return deferMaybe(-1)
    }

    open func getClientsAndTabs() -> Deferred<Maybe<[ClientAndTabs]>> {
        return deferMaybe(self.clientsAndTabs)
    }

    open func getClients() -> Deferred<Maybe<[RemoteClient]>> {
        return deferMaybe(self.clientsAndTabs.map { $0.client })
    }

    open func getClientWithId(_ clientID: GUID) -> Deferred<Maybe<RemoteClient?>> {
        return deferMaybe(self.clientsAndTabs.find { clientAndTabs in
            return clientAndTabs.client.guid == clientID
            }?.client)
    }

    open func getClientGUIDs() -> Deferred<Maybe<Set<GUID>>> {
        return deferMaybe(Set<GUID>(optFilter(self.clientsAndTabs.map { $0.client.guid })))
    }

    open func getTabsForClientWithGUID(_ guid: GUID?) -> Deferred<Maybe<[RemoteTab]>> {
        return deferMaybe(optFilter(self.clientsAndTabs.map { $0.client.guid == guid ? $0.tabs : nil })[0])
    }

    open func deleteCommands() -> Success {
        self.commands = [GUID: [SyncCommand]]()
        return succeed()
    }
    open func deleteCommands(_ clientGUID: GUID) -> Success {
        self.commands[clientGUID] = [SyncCommand]()
        return succeed()
    }

    open func getCommands() -> Deferred<Maybe<[GUID: [SyncCommand]]>> {
        return deferMaybe(self.commands)
    }

    open func insertCommand(_ command: SyncCommand, forClients clients: [RemoteClient]) -> Deferred<Maybe<Int>> {
        return self.insertCommands([command], forClients: clients)
    }
    open func insertCommands(_ commands: [SyncCommand], forClients clients: [RemoteClient]) -> Deferred<Maybe<Int>> {
        var numInserts = 0
        for client in clients {
            // Arrays are passed by value, that's why this is convoluted
            if (self.commands[client.guid ?? "localID"] != nil) {
                self.commands[client.guid ?? "localID"]! += commands
                numInserts += commands.count
            }
        }
        return deferMaybe(numInserts)
    }
}
