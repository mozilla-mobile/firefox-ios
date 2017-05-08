/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
@testable import Storage

import XCTest
import SwiftyJSON

func byValue(_ a: SyncCommand, b: SyncCommand) -> Bool {
    return a.value < b.value
}

func byClient(_ a: RemoteClient, b: RemoteClient) -> Bool {
    return a.guid! < b.guid!
}

class SyncCommandsTests: XCTestCase {

    var clients: [RemoteClient] = [RemoteClient]()
    var clientsAndTabs: SQLiteRemoteClientsAndTabs!

    var shareItems = [ShareItem]()

    var multipleCommands: [ShareItem] = [ShareItem]()
    var wipeCommand: SyncCommand!
    var db: BrowserDB!

    override func setUp() {
        let files = MockFiles()
        do {
            try files.remove("browser.db")
        } catch _ {
        }
        db = BrowserDB(filename: "browser.db", files: files)
        db.attachDB(filename: "metadata.db", as: AttachedDatabaseMetadata)
        // create clients

        let now = Date.now()
        let client1GUID = Bytes.generateGUID()
        let client2GUID = Bytes.generateGUID()
        let client3GUID = Bytes.generateGUID()

        self.clients.append(RemoteClient(guid: client1GUID, name: "Test client 1", modified: (now - OneMinuteInMilliseconds), type: "mobile", formfactor: "largetablet", os: "iOS"))
        self.clients.append(RemoteClient(guid: client2GUID, name: "Test client 2", modified: (now - OneHourInMilliseconds), type: "desktop", formfactor: "laptop", os: "Darwin"))
        self.clients.append(RemoteClient(guid: client3GUID, name: "Test local client", modified: (now - OneMinuteInMilliseconds), type: "mobile", formfactor: "largetablet", os: "iOS"))
        clientsAndTabs = SQLiteRemoteClientsAndTabs(db: db)
        clientsAndTabs.insertOrUpdateClients(clients).succeeded()

        shareItems.append(ShareItem(url: "http://mozilla.com", title: "Mozilla", favicon: nil))
        shareItems.append(ShareItem(url: "http://slashdot.org", title: "Slashdot", favicon: nil))
        shareItems.append(ShareItem(url: "http://news.bbc.co.uk", title: "BBC News", favicon: nil))
        shareItems.append(ShareItem(url: "http://news.bbc.co.uk", title: nil, favicon: nil))

        wipeCommand = SyncCommand(value: "{'command':'wipeAll', 'args':[]}")
    }

    override func tearDown() {
        clientsAndTabs.deleteCommands().succeeded()
        clientsAndTabs.clear().succeeded()
    }

    func testCreateSyncCommandFromShareItem() {
        let shareItem = shareItems[0]
        let syncCommand = SyncCommand.displayURIFromShareItem(shareItem, asClient: "abcdefghijkl")
        XCTAssertNil(syncCommand.commandID)
        XCTAssertNotNil(syncCommand.value)
        let jsonObj: [String: Any] = [
            "command": "displayURI",
            "args": [shareItem.url, "abcdefghijkl", shareItem.title ?? ""]
        ]
        XCTAssertEqual(JSON(object: jsonObj).stringValue(), syncCommand.value)
    }

    func testInsertWithNoURLOrTitle() {
        // Test insert command to table for
        let e = self.expectation(description: "Insert.")
        clientsAndTabs.insertCommand(self.wipeCommand, forClients: clients).upon {
            XCTAssertTrue($0.isSuccess)
            XCTAssertEqual(3, $0.successValue!)

            var error2: NSError? = nil
            let commandCursor = self.db.withConnection(&error2) { (connection, err) -> Cursor<Int> in
                let select = "SELECT COUNT(*) FROM \(TableSyncCommands)"
                return connection.executeQuery(select, factory: IntFactory, withArgs: nil)
            }
            XCTAssertNil(error2)
            XCTAssertNotNil(commandCursor[0])
            XCTAssertEqual(3, commandCursor[0]!)
            e.fulfill()
        }
        self.waitForExpectations(timeout: 5, handler: nil)
    }

    func testInsertWithURLOnly() {
        let shareItem = shareItems[3]
        let syncCommand = SyncCommand.displayURIFromShareItem(shareItem, asClient: "abcdefghijkl")

        let e = self.expectation(description: "Insert.")
        clientsAndTabs.insertCommand(syncCommand, forClients: clients).upon {
            XCTAssertTrue($0.isSuccess)
            XCTAssertEqual(3, $0.successValue!)

            var error: NSError? = nil
            let commandCursor = self.db.withConnection(&error) { (connection, err) -> Cursor<Int> in
                let select = "SELECT COUNT(*) FROM \(TableSyncCommands)"
                return connection.executeQuery(select, factory: IntFactory, withArgs: nil)
            }
            XCTAssertNil(error)
            XCTAssertNotNil(commandCursor[0])
            XCTAssertEqual(3, commandCursor[0]!)
            e.fulfill()
        }
        self.waitForExpectations(timeout: 5, handler: nil)
    }

    func testInsertWithMultipleCommands() {
        let e = self.expectation(description: "Insert.")
        let syncCommands = shareItems.map { item in
            return SyncCommand.displayURIFromShareItem(item, asClient: "abcdefghijkl")
        }
        clientsAndTabs.insertCommands(syncCommands, forClients: clients).upon {
            XCTAssertTrue($0.isSuccess)
            XCTAssertEqual(12, $0.successValue!)

            var error: NSError? = nil
            let commandCursor = self.db.withConnection(&error) { (connection, err) -> Cursor<Int> in
                let select = "SELECT COUNT(*) FROM \(TableSyncCommands)"
                return connection.executeQuery(select, factory: IntFactory, withArgs: nil)
            }
            XCTAssertNil(error)
            XCTAssertNotNil(commandCursor[0])
            XCTAssertEqual(12, commandCursor[0]!)
            e.fulfill()
        }
        self.waitForExpectations(timeout: 5, handler: nil)
    }

    func testGetForAllClients() {
        let syncCommands = shareItems.map { item in
            return SyncCommand.displayURIFromShareItem(item, asClient: "abcdefghijkl")
        }.sorted(by: byValue)
        clientsAndTabs.insertCommands(syncCommands, forClients: clients).succeeded()

        let b = self.expectation(description: "Get for invalid client.")
        clientsAndTabs.getCommands().upon({ result in
            XCTAssertTrue(result.isSuccess)
            if let clientCommands = result.successValue {
                XCTAssertEqual(clientCommands.count, self.clients.count)
                for client in clientCommands.keys {
                    XCTAssertEqual(syncCommands, clientCommands[client]!.sorted(by: byValue))
                }
            } else {
                XCTFail("Expected no commands!")
            }
            b.fulfill()
        })
        self.waitForExpectations(timeout: 5, handler: nil)
    }

    func testDeleteForValidClient() {
        let syncCommands = shareItems.map { item in
            return SyncCommand.displayURIFromShareItem(item, asClient: "abcdefghijkl")
        }.sorted(by: byValue)

        var client = self.clients[0]
        let a = self.expectation(description: "delete for client.")
        let b = self.expectation(description: "Get for deleted client.")
        let c = self.expectation(description: "Get for not deleted client.")
        clientsAndTabs.insertCommands(syncCommands, forClients: clients).upon {
            XCTAssertTrue($0.isSuccess)
            XCTAssertEqual(12, $0.successValue!)

            let result = self.clientsAndTabs.deleteCommands(client.guid!).value
            XCTAssertTrue(result.isSuccess)
            a.fulfill()

            var error: NSError? = nil
            let commandCursor = self.db.withConnection(&error) { (connection, err) -> Cursor<Int> in
                let select = "SELECT COUNT(*) FROM \(TableSyncCommands) WHERE client_guid = '\(client.guid!)'"
                return connection.executeQuery(select, factory: IntFactory, withArgs: nil)
            }
            XCTAssertNil(error)
            XCTAssertNotNil(commandCursor[0])
            XCTAssertEqual(0, commandCursor[0]!)
            b.fulfill()

            client = self.clients[1]
            let commandCursor2 = self.db.withConnection(&error) { (connection, err) -> Cursor<Int> in
                let select = "SELECT COUNT(*) FROM \(TableSyncCommands) WHERE client_guid = '\(client.guid!)'"
                return connection.executeQuery(select, factory: IntFactory, withArgs: nil)
            }
            XCTAssertNil(error)
            XCTAssertNotNil(commandCursor2[0])
            XCTAssertEqual(4, commandCursor2[0]!)
            c.fulfill()
        }

        self.waitForExpectations(timeout: 5, handler: nil)
    }

    func testDeleteForAllClients() {
        let syncCommands = shareItems.map { item in
            return SyncCommand.displayURIFromShareItem(item, asClient: "abcdefghijkl")
        }

        let a = self.expectation(description: "Wipe for all clients.")
        let b = self.expectation(description: "Get for clients.")
        clientsAndTabs.insertCommands(syncCommands, forClients: clients).upon {
            XCTAssertTrue($0.isSuccess)
            XCTAssertEqual(12, $0.successValue!)

            let result = self.clientsAndTabs.deleteCommands().value
            XCTAssertTrue(result.isSuccess)
            a.fulfill()

            self.clientsAndTabs.getCommands().upon({ result in
                XCTAssertTrue(result.isSuccess)
                if let clientCommands = result.successValue {
                    XCTAssertEqual(0, clientCommands.count)
                } else {
                    XCTFail("Expected no commands!")
                }
                b.fulfill()
            })
        }
        
        self.waitForExpectations(timeout: 5, handler: nil)
    }
}
