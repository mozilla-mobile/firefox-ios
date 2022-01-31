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

    func testNoData() {
        let (manager, _) = createSUT()
        XCTAssertEqual(manager.testTabCountOnDisk(), 0, "Expected 0 tabs on disk")
        XCTAssertEqual(manager.testCountRestoredTabs(), 0)
    }

    func testPrivateTabsAreArchived() {
        let (manager, configuration) = createSUT()
        for _ in 0..<2 {
            addTabWithSessionData(manager: manager, configuration: configuration, isPrivate: true)
        }
        XCTAssertEqual(manager.tabs.count, 2)

        let expectation = expectation(description: "Saved store changes")
        manager.storeChanges(writeCompletion: {
            XCTAssertEqual(manager.testTabCountOnDisk(), 2)
            expectation.fulfill()
        })
        waitForExpectations(timeout: 20, handler: nil)
    }

    // Test disabled due to Issue:https://github.com/mozilla-mobile/firefox-ios/issues/7867
    /*
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
    }*/
}

private extension TabManagerStoreTests {

    // SUT = system under test
    func createSUT(file: StaticString = #file, line: UInt = #line) -> (TabManager, WKWebViewConfiguration) {
        let profile = TabManagerMockProfile()
        profile._reopen()
        let configuration = WKWebViewConfiguration()
        configuration.processPool = WKProcessPool()
        configureiPad()

        let manager = TabManager(profile: profile, imageStore: nil)
        manager.testClearArchive()

        trackForMemoryLeaks(manager, file: file, line: line)
        trackForMemoryLeaks(profile, file: file, line: line)
        trackForMemoryLeaks(configuration, file: file, line: line)
        return (manager, configuration)
    }

    func configureiPad() {
        guard UIDevice.current.userInterfaceIdiom == .pad else { return }
        // BVC.viewWillAppear() calls restoreTabs() which interferes with these tests.
        // (On iPhone, ClientTests never dismiss the intro screen, on iPad the intro is a popover on the BVC).
        // Wait for this to happen (UIView.window only gets assigned after viewWillAppear()), then begin testing.
        let bvc = (UIApplication.shared.delegate as! AppDelegate).browserViewController
        let predicate = XCTNSPredicateExpectation(predicate: NSPredicate(format: "view.window != nil"), object: bvc)
        wait(for: [predicate], timeout: 20)
    }

    func trackForMemoryLeaks(_ instance: AnyObject, file: StaticString = #file, line: UInt = #line) {
        addTeardownBlock { [weak instance] in
            XCTAssertNil(instance, "Instance should have been deallocated, potential memory leak.", file: file, line: line)
        }
    }

    // Without session data, a Tab can't become a SavedTab and get archived
    func addTabWithSessionData(manager: TabManager, configuration: WKWebViewConfiguration, isPrivate: Bool = false) {
        let tab = Tab(bvc: BrowserViewController.foregroundBVC(), configuration: configuration, isPrivate: isPrivate)
        tab.url = URL(string: "http://yahoo.com")!
        manager.configureTab(tab, request: URLRequest(url: tab.url!), flushToDisk: false, zombie: false)
        tab.sessionData = SessionData(currentPage: 0, urls: [tab.url!], lastUsedTime: Date.now())
    }
}
