// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import MozillaAppServices
import Shared
import XCTest

@testable import Storage

class MockRustRemoteTabs: RustRemoteTabs {
    override public func getAll() -> Deferred<Maybe<[ClientRemoteTabs]>> {
        let url = "https://example.com"
        let title = "example"
        let clientGUID = "AAAAA"
        let tab = RemoteTab(clientGUID: clientGUID,
                            URL: URL(string: url)!,
                            title: title,
                            history: [URL(string: url)!],
                            lastUsed: Date.now(),
                            icon: nil,
                            inactive: false)
        let clientRemoteTab = ClientRemoteTabs(clientId: clientGUID,
                                               clientName: "testClient",
                                               deviceType: .mobile,
                                               lastModified: Int64(Date.now()),
                                               remoteTabs: [tab.toRemoteTabRecord()])

        let url2 = "https://example2.com"
        let title2 = "example2"
        let clientGUID2 = "BBBBB"
        let tab2 = RemoteTab(clientGUID: clientGUID2,
                             URL: URL(string: url2)!,
                             title: title2,
                             history: [URL(string: url2)!],
                             lastUsed: Date.now(),
                             icon: nil,
                             inactive: false)

        let clientRemoteTab2 = ClientRemoteTabs(clientId: clientGUID2,
                                                clientName: "testClient2",
                                                deviceType: .mobile,
                                                lastModified: Int64(Date.now()),
                                                remoteTabs: [tab2.toRemoteTabRecord()])
        return deferMaybe([clientRemoteTab, clientRemoteTab2])
    }
}

class RustRemoteTabsTests: XCTestCase {
    var files: FileAccessor!
    var tabs: RustRemoteTabs!
    var mockTabs: MockRustRemoteTabs!

    override func setUp() {
        super.setUp()
        files = MockFiles()

        if let rootDirectory = try? files.getAndEnsureDirectory() {
            let databasePath = URL(
                fileURLWithPath: rootDirectory,
                isDirectory: true
            ).appendingPathComponent("testTabs.db").path
            try? files.remove("testTabs.db")

            let mockDatabasePath = URL(fileURLWithPath: rootDirectory,
                                       isDirectory: true)
                                        .appendingPathComponent("mockTestTabs.db")
                                        .path
            try? files.remove("mockTestTabs.db")

            tabs = RustRemoteTabs(databasePath: databasePath)
            mockTabs = MockRustRemoteTabs(databasePath: mockDatabasePath)
            _ = tabs.reopenIfClosed()
            _ = mockTabs.reopenIfClosed()
        } else {
            XCTFail("Could not retrieve root directory")
        }
    }

    func testSetLocalTabs() {
        let url = "https://example.com"
        let title = "example"
        let tab = RemoteTab(
            clientGUID: nil,
            URL: URL(string: url)!,
            title: title,
            history: [URL(string: url)!],
            lastUsed: Date.now(),
            icon: nil,
            inactive: false
        )

        let count = tabs.setLocalTabs(localTabs: [tab])
            // We are just checking that the `setLocalTabs` call did not return an
            // error as the RustRemoteTabs `getAll` function doesn't not return local tabs.
        XCTAssertTrue(count.value.isSuccess)
        XCTAssertEqual(count.value.successValue, 1)
    }

    func testGetAll() {
        let clientRemoteTabs = tabs.getAll()

        // We are only testing that the `getAll` call did not return an error as
        // this function will only return values after syncing remote records.
        XCTAssertTrue(clientRemoteTabs.value.isSuccess)
        XCTAssertEqual(clientRemoteTabs.value.successValue!.count, 0)
    }

    func testGetClient() {
        let result = mockTabs.getClient(fxaDeviceId: "BBBBB")
        XCTAssertTrue(result.value.isSuccess)
        let clientGUID = result.value.successValue??.guid
        XCTAssertEqual("BBBBB", clientGUID)
    }

    func testGetClientGUIDs() {
        mockTabs.getClientGUIDs { (result, error) in
            XCTAssertNotNil(result)
            XCTAssertEqual(result!.count, 2)
            XCTAssertTrue(result!.contains("AAAAA"))
            XCTAssertTrue(result!.contains("BBBBB"))
        }
    }

    func testGetRemoteClients() {
        let deviceToExclude = "CCCCC"
        let remoteDeviceIds = ["AAAAA", "BBBBB", deviceToExclude]
        let result = mockTabs.getRemoteClients(remoteDeviceIds: remoteDeviceIds)
        XCTAssertTrue(result.value.isSuccess)
        let remoteClients = result.value.successValue!
        XCTAssertEqual(remoteClients.count, 2)
        XCTAssertTrue(remoteDeviceIds.contains(remoteClients[0].client.fxaDeviceId!))
        XCTAssertTrue(remoteDeviceIds.contains(remoteClients[1].client.fxaDeviceId!))

        let filteredResult = remoteClients.filter {
            $0.client.fxaDeviceId == deviceToExclude
        }
        XCTAssertTrue(filteredResult.isEmpty)
    }

    func testAddRemoteCommand() {
        mockTabs.tabsCommandQueue?.getUnsentCommands { getResult in
            switch getResult {
            case .success(let commands):
                // checking that the command queue is empty
                XCTAssert(commands.isEmpty)

                // adding the record to the command queue
                let deviceId = "AAAAAA"
                let url = "https://test.com"
                self.mockTabs.tabsCommandQueue?.addRemoteCommand(deviceId: deviceId,
                                                                 command: .closeTab(url: url)) { addResult in
                    switch addResult {
                    case .success(let didAddCommand):
                        XCTAssert(didAddCommand)

                        // checking that the command queue has the added record
                        self.mockTabs.tabsCommandQueue?.getUnsentCommands { getResult2 in
                            switch getResult2 {
                            case .success(let commands2):
                                XCTAssertEqual(commands2.count, 1)
                                XCTAssertEqual(commands2[0].deviceId, deviceId)
                            case .failure(let error):
                                XCTFail("Expected to get unsent commands successfully after add \(error)")
                            }
                        }
                    case .failure(let error):
                        XCTFail("Expected to add a command successfully \(error)")
                    }
                }
            case .failure(let error):
                XCTFail("Expected to get unsent commands successfully \(error)")
            }
        }
    }

    func testRemoveRemoteCommand() {
        // adding the record to the command queue
        let deviceId = "BBBBBB"
        let url = "https://test.com"

        self.mockTabs.tabsCommandQueue?.addRemoteCommand(deviceId: deviceId, command: .closeTab(url: url)) { addResult in
            switch addResult {
            case .success(let didAddCommand):
                XCTAssertTrue(didAddCommand)

                // checking that the command queue has the added record
                self.mockTabs.tabsCommandQueue?.getUnsentCommands { getResult in
                    switch getResult {
                    case .success(let commands):
                        XCTAssertEqual(commands.count, 1)
                        XCTAssertEqual(commands[0].deviceId, deviceId)

                        // removing the record from the command queue
                        self.mockTabs.tabsCommandQueue?.removeRemoteCommand(deviceId: deviceId,
                                                                            command: .closeTab(url: url)) { removeResult in
                            switch removeResult {
                            case .success(let didRemove):
                                XCTAssert(didRemove)

                                // checking that record is removed from command queue
                                self.mockTabs.tabsCommandQueue?.getUnsentCommands { getResult2 in
                                    switch getResult2 {
                                    case .success(let commands2):
                                        XCTAssert(commands2.isEmpty)
                                    case .failure(let error):
                                        XCTFail("Expected to get unsent commands after remove successfully \(error)")
                                    }
                                }
                            case .failure(let error):
                                XCTFail("Expected to remove command successfully \(error)")
                            }
                        }
                    case .failure(let error):
                        XCTFail("Expected to get unsent commands successfully \(error)")
                    }
                }
            case .failure(let error):
                XCTFail("Expected to add a command successfully \(error)")
            }
        }
    }

    func testSetPendingCommandsSent() {
        // adding the record to the command queue
        let deviceId = "CCCCC"
        let url = "https://test.com"

        mockTabs.tabsCommandQueue?.addRemoteCommand(deviceId: deviceId, command: .closeTab(url: url)) { addResult in
            switch addResult {
            case .success(let didAddCommand):
                XCTAssertTrue(didAddCommand)

                // retrieving unsent commands
                self.mockTabs.tabsCommandQueue?.getUnsentCommands { getResult in
                    switch getResult {
                    case .success(let commands):
                        XCTAssertEqual(commands.count, 1)
                        XCTAssertEqual(commands[0].deviceId, deviceId)

                        // setting command as sent
                        let command = PendingCommand(deviceId: deviceId,
                                                     command: .closeTab(url: url),
                                                     timeRequested: Date().toMillisecondsSince1970(),
                                                     timeSent: nil)
                        self.mockTabs.tabsCommandQueue?.setPendingCommandsSent(deviceId: deviceId,
                                                                               commands: [command]) { errors in
                            XCTAssert(errors.isEmpty)

                            // retrieving unsent commands
                            self.mockTabs.tabsCommandQueue?.getUnsentCommands { getResult2 in
                                switch getResult2 {
                                case .success(let commands):
                                    XCTAssert(commands.isEmpty)
                                case .failure(let error):
                                    XCTFail("Expected to retrieve unsent commands successfully \(error)")
                                }
                            }
                        }
                    case .failure(let error):
                        XCTFail("Expected to retrieve added unsent command successfully \(error)")
                    }
                }
            case .failure(let error):
                XCTFail("Expected to add a command successfully \(error)")
            }
        }
    }

    func testGetUnsentCommandUrlsByDeviceId() {
        // adding the record to the command queue
        let deviceId = "DDDD"
        let url = "https://test.com"
        let url2 = "https://test2.com"

        mockTabs.tabsCommandQueue?.addRemoteCommand(deviceId: deviceId, command: .closeTab(url: url)) { addResult in
            switch addResult {
            case .success(let didAddCommand):
                XCTAssert(didAddCommand)

                // adding another record to the command queue
                self.mockTabs.tabsCommandQueue?.addRemoteCommand(deviceId: deviceId,
                                                                 command: .closeTab(url: url2)) { addResult2 in
                    switch addResult2 {
                    case .success(let didAddCommit2):
                        XCTAssert(didAddCommit2)

                        // getting unsent command urls
                        self.mockTabs.getUnsentCommandUrlsByDeviceId(deviceId: deviceId) { urls in
                            XCTAssertEqual(urls.count, 2)
                            XCTAssert(urls.contains(url))
                            XCTAssert(urls.contains(url2))
                        }
                    case .failure(let error):
                        XCTFail("Expected to add second command successfully \(error)")
                    }
                }
            case .failure(let error):
                XCTFail("Expected to add a command succesfully \(error)")
            }
        }
    }

    func testGetSentCommands() {
        let commandUrl1 = "https://test3.com"
        let commandUrl2 = "https://test4.com"
        let unsentCommandUrls = [commandUrl1]
        let command1 = PendingCommand(deviceId: "EEEEEE",
                                      command: .closeTab(url: commandUrl1),
                                      timeRequested: Date().toMillisecondsSince1970(),
                                      timeSent: nil)
        let command2 = PendingCommand(deviceId: "EEEEEE",
                                      command: .closeTab(url: commandUrl2),
                                      timeRequested: Date().toMillisecondsSince1970(),
                                      timeSent: nil)
        let commands = [command1, command2]

        let sentCommands = mockTabs.getSentCommands(unsentCommandUrls: unsentCommandUrls, commands: commands)

        XCTAssertEqual(sentCommands.count, 1)

        switch sentCommands[0].command {
        case .closeTab(let url):
            XCTAssertEqual(url, commandUrl2)
        }
    }
}
