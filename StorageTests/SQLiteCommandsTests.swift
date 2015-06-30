//
//  SQLiteCommandsTests.swift
//  Client
//
//  Created by Emily Toop on 6/30/15.
//  Copyright (c) 2015 Mozilla. All rights reserved.
//

import Foundation
import Shared
import XCTest



func byGuid(a: SyncCommand, b: SyncCommand) -> Bool {
    return a.guid < b.guid
}

class SQLiteCommandsTests: XCTestCase {

    var commands: SQLiteCommands!

    var clients: [RemoteClient] = [RemoteClient]()
    var clientsAndTabs: SQLiteRemoteClientsAndTabs!

    var multipleCommands: [SyncCommand] = [SyncCommand]()
    var emptyCommand: SyncCommand!
    var urlOnlyCommand: SyncCommand!
    var titleOnlyCommand: SyncCommand!
    var invalidClientCommand: SyncCommand!

    override func setUp() {
        let files = MockFiles()
        files.remove("browser.db")
        let db = BrowserDB(filename: "browser.db", files: files)
        commands = SQLiteCommands(db: db)

        // create clients

        let now = NSDate.now()
        let client1GUID = Bytes.generateGUID()
        let client2GUID = Bytes.generateGUID()

        self.clients.append(RemoteClient(guid: client1GUID, name: "Test client 1", modified: (now - OneMinuteInMilliseconds), type: "mobile", formfactor: "largetablet", os: "iOS"))
        self.clients.append(RemoteClient(guid: client2GUID, name: "Test client 2", modified: (now - OneHourInMilliseconds), type: "desktop", formfactor: "laptop", os: "Darwin"))
        self.clients.append(RemoteClient(guid: nil, name: "Test local client", modified: (now - OneMinuteInMilliseconds), type: "mobile", formfactor: "largetablet", os: "iOS"))
        clientsAndTabs = SQLiteRemoteClientsAndTabs(db: db)
        clientsAndTabs.insertOrUpdateClients(clients)


        multipleCommands.append(SyncCommand(guid: Bytes.generateGUID(), clientGuid: self.clients[0].guid!, url: "http://mozilla.com",    title: "Mozilla", action: "sendtab", lastUsed: NSDate.now()))
        multipleCommands.append(SyncCommand(guid: Bytes.generateGUID(), clientGuid: self.clients[1].guid!, url: "http://slashdot.org",    title: "Slashdot", action: "sendtab", lastUsed: NSDate.now()))
        multipleCommands.append(SyncCommand(guid: Bytes.generateGUID(), clientGuid: self.clients[0].guid!, url: "http://news.bbc.co.uk",    title: "BBC News", action: "sendtab", lastUsed: NSDate.now()))
        emptyCommand = SyncCommand(guid: Bytes.generateGUID(), clientGuid: self.clients[0].guid!, url: nil, title: nil, action: "sendtab", lastUsed: NSDate.now())
        urlOnlyCommand = SyncCommand(guid: Bytes.generateGUID(), clientGuid: self.clients[1].guid!, url: "http://mozilla.com", title: nil, action: "sendtab", lastUsed: NSDate.now())
        titleOnlyCommand = SyncCommand(guid: Bytes.generateGUID(), clientGuid: self.clients[1].guid!, url: nil, title: "Empty Command", action: "sendtab", lastUsed: NSDate.now())
        invalidClientCommand = SyncCommand(guid: Bytes.generateGUID(), clientGuid: Bytes.generateGUID(), url: "http://mozilla.com",    title: "Mozilla", action: "sendtab", lastUsed: NSDate.now())
    }

    override func tearDown() {
        commands.wipeCommands()
        clientsAndTabs.clear()
    }

    func testInsertWithNoURLORTitle() {
        // Test insert command to table for
        let e = self.expectationWithDescription("Insert.")
        commands.insertCommand(self.emptyCommand).upon {
            XCTAssertTrue($0.isSuccess)
            e.fulfill()
        }
        self.waitForExpectationsWithTimeout(5, handler: nil)
    }

    func testInsertWithURLOnly() {
        let e = self.expectationWithDescription("Insert.")
        commands.insertCommand(self.urlOnlyCommand).upon {
            XCTAssertTrue($0.isSuccess)
            e.fulfill()
        }
        self.waitForExpectationsWithTimeout(5, handler: nil)
    }

    func testInsertWithTitleOnly() {
        let e = self.expectationWithDescription("Insert.")
        commands.insertCommand(self.titleOnlyCommand).upon {
            XCTAssertTrue($0.isSuccess)
            e.fulfill()
        }
        self.waitForExpectationsWithTimeout(5, handler: nil)
    }

    func testInsertWithURLAndTitle() {
        let e = self.expectationWithDescription("Insert.")
        commands.insertCommand(self.multipleCommands[0]).upon {
            XCTAssertTrue($0.isSuccess)
            e.fulfill()
        }
        self.waitForExpectationsWithTimeout(5, handler: nil)
    }

    func testInsertWithMultipleCommands() {

        let e = self.expectationWithDescription("Insert.")
        commands.insertCommands(self.multipleCommands).upon {
            XCTAssertTrue($0.isSuccess)
            e.fulfill()
        }
        self.waitForExpectationsWithTimeout(5, handler: nil)
    }

    func testInsertFailsWhenInvalidClient() {
        let e = self.expectationWithDescription("Insert.")
        commands.insertCommand(self.invalidClientCommand).upon {
            XCTAssertTrue($0.isFailure)
            e.fulfill()
        }
        self.waitForExpectationsWithTimeout(5, handler: nil)
    }

    func testGetForValidClient() {
        let expectedClient1 = [
            self.multipleCommands[0],
            self.multipleCommands[2],
            self.emptyCommand
            ].sorted(byGuid)
        let e = self.expectationWithDescription("Insert.")
        commands.insertCommands(self.multipleCommands + [self.emptyCommand, self.urlOnlyCommand, self.titleOnlyCommand]).upon {
            XCTAssertTrue($0.isSuccess)
            if let numOfCreatedRecords = $0.successValue {
                XCTAssertEqual(6, numOfCreatedRecords)
            }
            e.fulfill()
        }

        let a = self.expectationWithDescription("Get for client 1.")
        var client = self.clients[0]
        commands.getCommandsForClient(client).upon({ result in
            if let clientCommands = result.successValue {
                XCTAssertEqual(expectedClient1, clientCommands.sorted(byGuid))
            } else {
                XCTFail("Expected commands!")
            }
            a.fulfill()
        })

        let expectedClient2 = [
            self.multipleCommands[1],
            self.urlOnlyCommand,
            self.titleOnlyCommand
        ].sorted(byGuid)
        client = self.clients[1]

        let b = self.expectationWithDescription("Get for client 2.")
        commands.getCommandsForClient(client).upon({ result in
            if let clientCommands = result.successValue {
                XCTAssertEqual(expectedClient2, clientCommands.sorted(byGuid))
            } else {
                XCTFail("Expected commands!")
            }
            b.fulfill()
        })
        self.waitForExpectationsWithTimeout(10, handler: nil)
    }

    func testGetForInvalidClient() {
        let e = self.expectationWithDescription("Insert.")
        commands.insertCommands(self.multipleCommands + [self.emptyCommand, self.urlOnlyCommand, self.titleOnlyCommand]).upon {
            XCTAssertTrue($0.isSuccess)
            if let numOfCreatedRecords = $0.successValue {
                XCTAssertEqual(6, numOfCreatedRecords)
            }
            e.fulfill()
        }
        let b = self.expectationWithDescription("Get for invalid client.")
        commands.getCommandsForClient(RemoteClient(guid: Bytes.generateGUID(), name: "Invalid client 1", modified: (NSDate.now() - OneMinuteInMilliseconds), type: "mobile", formfactor: "largetablet", os: "iOS")).upon({ result in
            XCTAssertTrue(result.isSuccess)
            if let clientCommands = result.successValue {
                XCTAssertEqual([], clientCommands)
            } else {
                XCTFail("Expected commands!")
            }
            b.fulfill()
        })
        self.waitForExpectationsWithTimeout(5, handler: nil)
    }

    func testGetForAllClients() {
        let expected = (self.multipleCommands + [self.emptyCommand, self.urlOnlyCommand, self.titleOnlyCommand]).sorted(byGuid)
        let e = self.expectationWithDescription("Insert.")
        commands.insertCommands(expected).upon {
            XCTAssertTrue($0.isSuccess)
            if let numOfCreatedRecords = $0.successValue {
                XCTAssertEqual(6, numOfCreatedRecords)
            }
            e.fulfill()
        }
        let b = self.expectationWithDescription("Get for invalid client.")
        commands.getCommands().upon({ result in
            XCTAssertTrue(result.isSuccess)
            if let clientCommands = result.successValue {
                XCTAssertEqual(expected, clientCommands.sorted(byGuid))
            } else {
                XCTFail("Expected no commands!")
            }
            b.fulfill()
        })
        self.waitForExpectationsWithTimeout(5, handler: nil)
    }
    
    func testWipeForValidClient() {
        let e = self.expectationWithDescription("Insert.")
        commands.insertCommands(self.multipleCommands + [self.emptyCommand, self.urlOnlyCommand, self.titleOnlyCommand]).upon {
            XCTAssertTrue($0.isSuccess)
            if let numOfCreatedRecords = $0.successValue {
                XCTAssertEqual(6, numOfCreatedRecords)
            }
            e.fulfill()
        }
        var client = self.clients[0]
        let a = self.expectationWithDescription("Wipe for client.")
        commands.wipeCommandsForClient(client).upon({ result in
            XCTAssertTrue(result.isSuccess)
            a.fulfill()
        })

        let b = self.expectationWithDescription("Get for wiped client.")
        commands.getCommandsForClient(client).upon({ result in
            XCTAssertTrue(result.isSuccess)
            if let clientCommands = result.successValue {
                XCTAssertEqual([], clientCommands)
            } else {
                XCTFail("Expected no commands!")
            }
            b.fulfill()
        })

        self.waitForExpectationsWithTimeout(5, handler: nil)
    }
    
    func testWipeForAllClients() {
        let e = self.expectationWithDescription("Insert.")
        commands.insertCommands(self.multipleCommands + [self.emptyCommand, self.urlOnlyCommand, self.titleOnlyCommand]).upon {
            XCTAssertTrue($0.isSuccess)
            if let numOfCreatedRecords = $0.successValue {
                XCTAssertEqual(6, numOfCreatedRecords)
            }
            e.fulfill()
        }

        let a = self.expectationWithDescription("Wipe for all clients.")
        commands.wipeCommands().upon({ result in
            XCTAssertTrue(result.isSuccess)
            a.fulfill()
        })

        let b = self.expectationWithDescription("Get for clients.")
        commands.getCommands().upon({ result in
            XCTAssertTrue(result.isSuccess)
            if let clientCommands = result.successValue {
                XCTAssertEqual([], clientCommands)
            } else {
                XCTFail("Expected no commands!")
            }
            b.fulfill()
        })

        self.waitForExpectationsWithTimeout(5, handler: nil)
    }
}