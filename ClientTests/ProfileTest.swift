/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import XCTest
import Storage
import Shared

/*
 * A base test type for tests that need a profile.
 */
class ProfileTest: XCTestCase {
    var clients: [RemoteClient]?
    var url: String?
    var title: String?

    func withTestProfile(callback: (profile: Profile) -> Void) {
        callback(profile: MockProfile())
    }

//
//    func assertCommands(commands: [SyncCommand]) {
//        if let remoteClients = clients,
//            let itemURL = url,
//            let itemTitle = title {
//            XCTAssertEqual(remoteClients.count, commands.count)
//            for command in commands {
//                XCTAssertEqual(itemURL, command.url!)
//                XCTAssertEqual(itemTitle, command.title!)
//            }
//        }
//    }
//
//
//    func testShareItemAddsToDatabase() {
//        let url = "http://mozilla.com"
//        let title = "Mozilla"
//        let shareItem = ShareItem(url: url, title: title, favicon: nil)
//
//        // create clients
//        let client1GUID = Bytes.generateGUID()
//        let client2GUID = Bytes.generateGUID()
//
//        clients = [RemoteClient(guid: client1GUID, name: "Test client 1", modified: NSDate.now(), type: "mobile", formfactor: "largetablet", os: "iOS"),
//            RemoteClient(guid: client2GUID, name: "Test client 2", modified: NSDate.now(), type: "desktop", formfactor: "laptop", os: "Darwin")]
//
//
//        class MockSQLiteCommands: SyncCommands {
//            // wipe all unsynced commands
//            func wipeCommands() -> Deferred<Result<()>> {
//                return Success()
//            }
//
//            // wipe unsynced commands for a client
//            func wipeCommandsForClient(client: RemoteClient) -> Deferred<Result<()>> {
//                return Success()
//            }
//
//            // insert a single command
//            func insertCommand(command: SyncCommand) -> Deferred<Result<Int>> {
//                return Deferred(value: Result(success: 0))
//            }
//
//            // insert a batch of commands
//            func insertCommands(commands: [SyncCommand]) -> Deferred<Result<Int>> {
//                assertCommands(commands)
//                return Deferred(value: Result(success: 3))
//            }
//
//            // get all unsynced commands
//            func getCommands() -> Deferred<Result<[SyncCommand]>> {
//                return Deferred(value: Result(success: []))
//            }
//
//            // get all unsyced commands for a client
//            func getCommandsForClient(client: RemoteClient) -> Deferred<Result<[SyncCommand]>> {
//                return Deferred(value: Result(success: []))
//            }
//
//            // we do something here when accounts are removed
//            func onRemovedAccount() -> Success {
//                return Success()
//            }
//        }
//
//        class TestBrowserProfile : BrowserProfile {
//            lazy var syncCommands: SyncCommands = {
//                return MockSQLiteCommands()
//            }()
//        }
//
//        let profile = TestBrowserProfile(localName: "TestBrowserProfile")
//        profile.sendItems([shareItem], toClients:clients!)
//    }
}
