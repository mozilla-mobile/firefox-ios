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

class TabManagerStoreTests: XCTestCase {
    let profile = TabManagerMockProfile()
    var manager: TabManager!
    let configuration = WKWebViewConfiguration()

    override func setUp() {
        super.setUp()

        manager = TabManager(profile: profile, imageStore: nil)
        configuration.processPool = WKProcessPool()

        manager.testClearArchive()

    }

    override func tearDown() {
        super.tearDown()
    }

    // Without session data, a Tab can't become a SavedTab and get archived
    func addTabWithSessionData(isPrivate: Bool = false) {
        let tab = Tab(configuration: configuration, isPrivate: isPrivate)
        tab.url = URL(string: "http://yahoo.com")!
        manager.configureTab(tab, request: URLRequest(url: tab.url!), flushToDisk: false, zombie: false)
        tab.sessionData = SessionData(currentPage: 0, urls: [tab.url!], lastUsedTime: Date.now())
    }

    func testNoData() {
        XCTAssertEqual(manager.testTabCountOnDisk(), 0, "Expected 0 tabs on disk")
        XCTAssertEqual(manager.testCountRestoredTabs(), 0)
    }

    func testPrivateTabsAreArchived() {
        for _ in 0..<2 {
            addTabWithSessionData(isPrivate: true)
        }
        let e = expectation(description: "saved")
        manager.storeChanges().uponQueue(.main) {_ in
            XCTAssertEqual(self.manager.testTabCountOnDisk(), 2)
            e.fulfill()
        }
        waitForExpectations(timeout: 2, handler: nil)
    }

    func testAddedTabsAreStored() {
        // Add 2 tabs
        for _ in 0..<2 {
            addTabWithSessionData()
        }

        var e = expectation(description: "saved")
        manager.storeChanges().uponQueue(.main) { _ in
            XCTAssertEqual(self.manager.testTabCountOnDisk(), 2)
            e.fulfill()
        }
        waitForExpectations(timeout: 2, handler: nil)

        // Add 2 more
        for _ in 0..<2 {
            addTabWithSessionData()
        }

        e = expectation(description: "saved")
        manager.storeChanges().uponQueue(.main) { _ in
            XCTAssertEqual(self.manager.testTabCountOnDisk(), 4)
            e.fulfill()
        }
        waitForExpectations(timeout: 2, handler: nil)

        // Remove all tabs, and add just 1 tab
        manager.removeAll()
        addTabWithSessionData()

        e = expectation(description: "saved")
        manager.storeChanges().uponQueue(.main) {_ in
            XCTAssertEqual(self.manager.testTabCountOnDisk(), 1)
            e.fulfill()
        }
        waitForExpectations(timeout: 2, handler: nil)
    }
}

