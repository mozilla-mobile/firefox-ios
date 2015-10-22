/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import XCTest

import Shared
import Storage
import WebKit

public class TabManagerMockProfile: MockProfile {
    override func storeTabs(tabs: [RemoteTab]) -> Deferred<Maybe<Int>> {
        return self.remoteClientsAndTabs.insertOrUpdateTabs(tabs)
    }
}

class TabManagerTests: XCTestCase {

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    func testTabManagerStoresChangesInDB() {
        let profile = TabManagerMockProfile()
        let manager = TabManager(defaultNewTabRequest: NSURLRequest(URL: NSURL(fileURLWithPath: "http://localhost")), prefs: profile.prefs, imageStore: nil)
        let configuration = WKWebViewConfiguration()
        configuration.processPool = WKProcessPool()

        profile.remoteClientsAndTabs.wipeTabs()

        // Make sure we start with no remote tabs.
        var remoteTabs: [RemoteTab]?
        waitForCondition {
            remoteTabs = profile.remoteClientsAndTabs.getTabsForClientWithGUID(nil).value.successValue
            return remoteTabs?.count == 0
        }
        XCTAssertEqual(remoteTabs?.count, 0)

        // test that non-private tabs are saved to the db
        // add some non-private tabs to the tab manager
        for _ in 0..<3 {
            let tab = Browser(configuration: configuration)
            manager.configureTab(tab, request: NSURLRequest(URL: NSURL(string: "http://yahoo.com")!), flushToDisk: false, zombie: false, restoring: false)
        }

        manager.storeChanges()

        // now test that the database contains 3 tabs
        waitForCondition {
            remoteTabs = profile.remoteClientsAndTabs.getTabsForClientWithGUID(nil).value.successValue
            return remoteTabs?.count == 3
        }
        XCTAssertEqual(remoteTabs?.count, 3)

        // test that private tabs are not saved to the DB
        // private tabs are only available in iOS9 so don't execute this part of the test if we're testing against < iOS9
        if #available(iOS 9, *) {
            // create some private tabs
            for _ in 0..<3 {
                let tab = Browser(configuration: configuration, isPrivate: true)
                manager.configureTab(tab, request: NSURLRequest(URL: NSURL(string: "http://yahoo.com")!), flushToDisk: false, zombie: false, restoring: false)
            }

            manager.storeChanges()

            // We can't use waitForCondition here since we're testing a non-change.
            wait(ProfileRemoteTabsSyncDelay * 2)

            // now test that the database still contains only 3 tabs
            remoteTabs = profile.remoteClientsAndTabs.getTabsForClientWithGUID(nil).value.successValue
            XCTAssertEqual(remoteTabs?.count, 3)
        }
    }
    
}
