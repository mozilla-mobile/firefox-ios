// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Shared
@testable import Client
@testable import Storage

class RustRemoteTabsTests: XCTestCase {
    var files: FileAccessor!
    var tabs: RustRemoteTabs!

    override func setUp() {
        files = MockFiles()

        if let rootDirectory = try? files.getAndEnsureDirectory() {
            let databasePath = URL(fileURLWithPath: rootDirectory, isDirectory: true).appendingPathComponent("testTabs.db").path
            try? files.remove("testTabs.db")

            tabs = RustRemoteTabs(databasePath: databasePath)
            _ = tabs.reopenIfClosed()
        } else {
            XCTFail("Could not retrieve root directory")
        }
    }

    func testSetLocalTabs() {
        let url = "https://example.com"
        let title = "example"
        let tab = RemoteTab(clientGUID: nil, URL: URL(string: url)!, title: title, history: [URL(string: url)!], lastUsed: Date.now(), icon: nil)

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
}
