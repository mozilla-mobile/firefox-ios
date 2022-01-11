// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

@testable import Client
import Shared
import Storage
import UIKit
import WebKit

import XCTest

class TabManagerStoreTests: XCTestCase {
    
    var profile: TabManagerMockProfile!
    var manager: TabManager!
    let configuration = WKWebViewConfiguration()

    override func setUp() {
        super.setUp()

        profile = TabManagerMockProfile()
        profile._reopen()
        manager = TabManager(profile: profile, imageStore: nil)
        configuration.processPool = WKProcessPool()

        if UIDevice.current.userInterfaceIdiom == .pad {
            // BVC.viewWillAppear() calls restoreTabs() which interferes with these tests.
            // (On iPhone, ClientTests never dismiss the intro screen, on iPad the intro is a popover on the BVC).
            // Wait for this to happen (UIView.window only gets assigned after viewWillAppear()), then begin testing.
            let bvc = (UIApplication.shared.delegate as! AppDelegate).browserViewController
            let predicate = XCTNSPredicateExpectation(predicate: NSPredicate(format: "view.window != nil"), object: bvc)
            wait(for: [predicate], timeout: 20)
        }

        manager.testClearArchive()
    }

    override func tearDown() {
        super.tearDown()

        profile._shutdown()
        manager.removeAll()

        manager = nil
        profile = nil
    }

    func testNoData() {
        XCTAssertEqual(manager.testTabCountOnDisk(), 0, "Expected 0 tabs on disk")
        XCTAssertEqual(manager.testCountRestoredTabs(), 0)
    }

    func testPrivateTabsAreArchived() {
        addTabsWithSessionData(numberOfTabs: 2, isPrivate: true)
        waitForStoreChanged(tabCountOnDisk: 2)
    }

    func testNormalTabsAreArchived() {
        addTabsWithSessionData(numberOfTabs: 2)
        waitForStoreChanged(tabCountOnDisk: 2)
    }

    func testAddingMultipleTabsInARow() {
        // Add 2 tabs
        addTabsWithSessionData(numberOfTabs: 2)
        waitForStoreChanged(tabCountOnDisk: 2)

        // Add 2 more tabs
        addTabsWithSessionData(numberOfTabs: 2, expectedTabsNumber: 4)
        waitForStoreChanged(tabCountOnDisk: 4)
    }

    func testRemoveTabs() {
        // Add 3 tabs
        addTabsWithSessionData(numberOfTabs: 3)
        waitForStoreChanged(tabCountOnDisk: 3)

        // Remove all tabs
        manager.removeAll()
        XCTAssertEqual(manager.testTabCountOnDisk(), 0, "Expected 0 tabs on disk")
    }

    func testAddTabsRemoveAndAddAgain() {
        // Add 2 tabs
        addTabsWithSessionData(numberOfTabs: 2)
        waitForStoreChanged(tabCountOnDisk: 2)

        // Remove all tabs
        manager.removeAll()
        XCTAssertEqual(manager.testTabCountOnDisk(), 0, "Expected 0 tabs on disk")

        // Add just 1 tab
        addTabsWithSessionData(numberOfTabs: 1)
        waitForStoreChanged(tabCountOnDisk: 1)
    }
}

// Helper functions for TabManagerStoreTests
extension TabManagerStoreTests {

    func addTabsWithSessionData(numberOfTabs: Int = 1, isPrivate: Bool = false, file: StaticString = #file, line: UInt = #line) {
        addTabsWithSessionData(numberOfTabs: numberOfTabs, expectedTabsNumber: numberOfTabs, isPrivate: isPrivate, file: file, line: line)
    }

    // Without session data, a Tab can't become a SavedTab and get archived
    func addTabsWithSessionData(numberOfTabs: Int = 1, expectedTabsNumber: Int, isPrivate: Bool = false, file: StaticString = #file, line: UInt = #line) {
        for _ in 0..<numberOfTabs {
            let tab = Tab(bvc: BrowserViewController.foregroundBVC(), configuration: configuration, isPrivate: isPrivate)
            tab.url = URL(string: "http://yahoo.com")!
            manager.configureTab(tab, request: URLRequest(url: tab.url!), flushToDisk: false, zombie: false)
            tab.sessionData = SessionData(currentPage: 0, urls: [tab.url!], lastUsedTime: Date.now())
        }

        XCTAssertEqual(manager.tabs.count, expectedTabsNumber, "Expected \(expectedTabsNumber) tabs in manager", file: file, line: line)
    }

    func waitForStoreChanged(tabCountOnDisk: Int, file: StaticString = #file, line: UInt = #line) {
        let expectation = expectation(description: "savedTabs")
        manager.storeChanges {
            let message = "There should be \(tabCountOnDisk) tabs on disk but there is \(self.manager.testTabCountOnDisk())"
            XCTAssertEqual(self.manager.testTabCountOnDisk(), tabCountOnDisk, message, file: file, line: line)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 20) { error in
            if let error = error { XCTFail("WaitForExpectations failed with: \(error.localizedDescription)", file: file, line: line) }
        }
    }
}
