// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation
import Shared
@testable import Storage
@testable import Client

import XCTest

open class MockRemoteClientsAndTabs: RemoteClientsAndTabs {
    public let clientsAndTabs: [ClientAndTabs]

    public init() {
        let now = Date.now()
        let client1GUID = Bytes.generateGUID()
        let client2GUID = Bytes.generateGUID()
        let u11 = URL(string: "http://test.com/test1")!
        let tab11 = RemoteTab(clientGUID: client1GUID, URL: u11, title: "Test 1", history: [    ], lastUsed: (now - OneMinuteInMilliseconds), icon: nil)

        let u12 = URL(string: "http://test.com/test2")!
        let tab12 = RemoteTab(clientGUID: client1GUID, URL: u12, title: "Test 2", history: [], lastUsed: (now - OneHourInMilliseconds), icon: nil)

        let tab21 = RemoteTab(clientGUID: client2GUID, URL: u11, title: "Test 1", history: [], lastUsed: (now - OneDayInMilliseconds), icon: nil)

        let u22 = URL(string: "http://different.com/test2")!
        let tab22 = RemoteTab(clientGUID: client2GUID, URL: u22, title: "Different Test 2", history: [], lastUsed: now + OneHourInMilliseconds, icon: nil)

        let client1 = RemoteClient(guid: client1GUID,
                                   name: "Test client 1",
                                   modified: (now - OneMinuteInMilliseconds),
                                   type: "mobile",
                                   formfactor: "largetablet",
                                   os: "iOS",
                                   version: "55.0.1",
                                   fxaDeviceId: "fxa1")
        let client2 = RemoteClient(guid: client2GUID,
                                   name: "Test client 2",
                                   modified: (now - OneHourInMilliseconds),
                                   type: "desktop",
                                   formfactor: "laptop",
                                   os: "Darwin",
                                   version: "55.0.1",
                                   fxaDeviceId: "fxa2")

        let localClient = RemoteClient(guid: nil,
                                       name: "Test local client",
                                       modified: (now - OneMinuteInMilliseconds),
                                       type: "mobile",
                                       formfactor: "largetablet",
                                       os: "iOS",
                                       version: "55.0.1",
                                       fxaDeviceId: "fxa3")
        let localUrl1 = URL(string: "http://test.com/testlocal1")!
        let localTab1 = RemoteTab(clientGUID: nil,
                                  URL: localUrl1,
                                  title: "Local test 1",
                                  history: [],
                                  lastUsed: (now - OneMinuteInMilliseconds),
                                  icon: nil)
        let localUrl2 = URL(string: "http://test.com/testlocal2")!
        let localTab2 = RemoteTab(clientGUID: nil,
                                  URL: localUrl2,
                                  title: "Local test 2",
                                  history: [],
                                  lastUsed: (now - OneMinuteInMilliseconds),
                                  icon: nil)

        // Tabs are ordered most-recent-first.
        self.clientsAndTabs = [ClientAndTabs(client: client1, tabs: [tab11, tab12]),
                               ClientAndTabs(client: client2, tabs: [tab22, tab21]),
                               ClientAndTabs(client: localClient, tabs: [localTab1, localTab2])]
    }

    open func onRemovedAccount() -> Success {
        return succeed()
    }

    open func wipeClients() -> Success {
        return succeed()
    }

    open func insertOrUpdateClients(_ clients: [RemoteClient]) -> Deferred<Maybe<Int>> {
        return deferMaybe(0)
    }

    open func insertOrUpdateClient(_ client: RemoteClient) -> Deferred<Maybe<Int>> {
        return deferMaybe(0)
    }

    open func getClients() -> Deferred<Maybe<[RemoteClient]>> {
        return deferMaybe(self.clientsAndTabs.map { $0.client })
    }

    public func getClient(guid: GUID) -> Deferred<Maybe<RemoteClient?>> {
        return deferMaybe(self.clientsAndTabs.find { clientAndTabs in
            return clientAndTabs.client.guid == guid
        }?.client)
    }

    public func getClient(fxaDeviceId: GUID) -> Deferred<Maybe<RemoteClient?>> {
        return deferMaybe(self.clientsAndTabs.find { clientAndTabs in
            return clientAndTabs.client.fxaDeviceId == fxaDeviceId
            }?.client)
    }

    open func getClientGUIDs() -> Deferred<Maybe<Set<GUID>>> {
        return deferMaybe(Set<GUID>(optFilter(self.clientsAndTabs.map { $0.client.guid })))
    }

    open func deleteClient(guid: GUID) -> Success { return succeed() }

    open func deleteCommands() -> Success { return succeed() }
    open func deleteCommands(_ clientGUID: GUID) -> Success { return succeed() }

    open func getCommands() -> Deferred<Maybe<[GUID: [SyncCommand]]>> { return deferMaybe([GUID: [SyncCommand]]()) }

    open func insertCommand(_ command: SyncCommand, forClients clients: [RemoteClient]) -> Deferred<Maybe<Int>> { return deferMaybe(0) }
    open func insertCommands(_ commands: [SyncCommand], forClients clients: [RemoteClient]) -> Deferred<Maybe<Int>> { return deferMaybe(0) }
}

func removeLocalClient(_ a: ClientAndTabs) -> Bool {
    return a.client.guid != nil
}

class SQLRemoteClientsAndTabsTests: XCTestCase {
    var clientsAndTabs: SQLiteRemoteClientsAndTabs!

    lazy var clients: [ClientAndTabs] = MockRemoteClientsAndTabs().clientsAndTabs

    override func setUp() {
        let files = MockFiles()
        do {
            try files.remove("browser.db")
        } catch _ {
        }
        clientsAndTabs = SQLiteRemoteClientsAndTabs(db: BrowserDB(filename: "browser.db", schema: BrowserSchema(), files: files))
    }

    func testReplaceRemoteDevices() {
        let device1 = RemoteDevice(id: "fx1", name: "Device 1", type: "mobile", isCurrentDevice: false, lastAccessTime: 12345678, availableCommands: [:])
        let device2 = RemoteDevice(id: "fx2", name: "Device 2 (local)", type: "desktop", isCurrentDevice: true, lastAccessTime: nil, availableCommands: [:])
        let device3 = RemoteDevice(id: nil, name: "Device 3 (faulty)", type: "desktop", isCurrentDevice: false, lastAccessTime: 12345678, availableCommands: [:])
        let device4 = RemoteDevice(id: "fx4", name: "Device 4 (faulty)", type: nil, isCurrentDevice: false, lastAccessTime: 12345678, availableCommands: [:])

        clientsAndTabs.replaceRemoteDevices([device1, device2, device3, device4]).succeeded()

        let devices = clientsAndTabs.db.runQuery("SELECT * FROM remote_devices", args: nil, factory: SQLiteRemoteClientsAndTabs.remoteDeviceFactory).value.successValue!.asArray()
        XCTAssertEqual(devices.count, 1) // Faulty devices + local device were not inserted.

        let device5 = RemoteDevice(id: "fx5", name: "Device 5", type: "mobile", isCurrentDevice: false, lastAccessTime: 12345678, availableCommands: [:])
        clientsAndTabs.replaceRemoteDevices([device5]).succeeded()

        let newDevices = clientsAndTabs.db.runQuery("SELECT * FROM remote_devices", args: nil, factory: SQLiteRemoteClientsAndTabs.remoteDeviceFactory).value.successValue!.asArray()
        XCTAssertEqual(newDevices.count, 1) // replaceRemoteDevices wipes the whole list before inserting.
    }
}
