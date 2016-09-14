/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

@testable import Client
import Shared
import Storage
import UIKit
import WebKit
import Deferred

import XCTest


public class TabManagerMockProfile: MockProfile {
    var numberOfTabsStored = 0
    override func storeTabs(tabs: [RemoteTab]) -> Deferred<Maybe<Int>> {
        numberOfTabsStored = tabs.count
        return deferMaybe(tabs.count)
    }
}

public class MockTabManagerStateDelegate: TabManagerStateDelegate {
    var numberOfTabsStored = 0
    func tabManagerWillStoreTabs(tabs: [Tab]) {
        numberOfTabsStored = tabs.count
    }
}

class TabManagerTests: XCTestCase {

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    func testTabManagerCallsTabManagerStateDelegateOnStoreChangesWithNormalTabs() {
        let profile = TabManagerMockProfile()
        let manager = TabManager(prefs: profile.prefs, imageStore: nil)
        let stateDelegate = MockTabManagerStateDelegate()
        manager.stateDelegate = stateDelegate
        let configuration = WKWebViewConfiguration()
        configuration.processPool = WKProcessPool()

        // test that non-private tabs are saved to the db
        // add some non-private tabs to the tab manager
        for _ in 0..<3 {
            let tab = Tab(configuration: configuration)
            tab.url = NSURL(string: "http://yahoo.com")!
            manager.configureTab(tab, request: NSURLRequest(URL: tab.url!), flushToDisk: false, zombie: false)
        }

        manager.storeChanges()

        XCTAssertEqual(stateDelegate.numberOfTabsStored, 3, "Expected state delegate to have been called with 3 tabs, but called with \(stateDelegate.numberOfTabsStored)")
    }

    @available(iOS 9, *)
    func testTabManagerDoesNotCallTabManagerStateDelegateOnStoreChangesWithPrivateTabs() {
        let profile = TabManagerMockProfile()
        let manager = TabManager(prefs: profile.prefs, imageStore: nil)
        let stateDelegate = MockTabManagerStateDelegate()
        manager.stateDelegate = stateDelegate
        let configuration = WKWebViewConfiguration()
        configuration.processPool = WKProcessPool()

        // test that non-private tabs are saved to the db
        // add some non-private tabs to the tab manager
        for _ in 0..<3 {
            let tab = Tab(configuration: configuration, isPrivate: true)
            tab.url = NSURL(string: "http://yahoo.com")!
            manager.configureTab(tab, request: NSURLRequest(URL: tab.url!), flushToDisk: false, zombie: false)
        }

        manager.storeChanges()

        XCTAssertEqual(stateDelegate.numberOfTabsStored, 0, "Expected state delegate to have been called with 3 tabs, but called with \(stateDelegate.numberOfTabsStored)")
    }
    
}
