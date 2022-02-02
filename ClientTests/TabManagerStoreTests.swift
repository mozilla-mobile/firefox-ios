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

    private var profile: TabManagerMockProfile!

    override func setUp() {
        super.setUp()
        profile = TabManagerMockProfile()
        profile._reopen()
    }

    override func tearDown() {
        super.tearDown()
        profile._shutdown()
        profile = nil
    }

    func testNoData() {
        let manager = createManager()
        XCTAssertEqual(manager.testTabCountOnDisk(), 0, "Expected 0 tabs on disk")
        XCTAssertEqual(manager.testCountRestoredTabs(), 0)
        XCTAssertEqual(profile.numberOfTabsStored, 0)
    }

    func testAddTabWithoutStoring_hasNoData() throws {
        throw XCTSkip("Test is failing intermittently on Bitrise")
//        let manager = createManager()
//        let configuration = createConfiguration()
//        addNumberOfTabs(manager: manager, configuration: configuration, tabNumber: 2)
//        XCTAssertEqual(manager.tabs.count, 2)
//        XCTAssertEqual(manager.testTabCountOnDisk(), 0)
//        XCTAssertEqual(profile.numberOfTabsStored, 0)
    }

    func testPrivateTabsAreArchived() throws {
        throw XCTSkip("Test is failing intermittently on Bitrise")
//        let manager = createManager()
//        let configuration = createConfiguration()
//        addNumberOfTabs(manager: manager, configuration: configuration, tabNumber: 2, isPrivate: true)
//        XCTAssertEqual(manager.tabs.count, 2)
//
//        // Private tabs aren't stored in remote tabs
//        waitStoreChanges(manager: manager, managerTabCount: 2, profileTabCount: 0)
    }

    func testNormalTabsAreArchived_storeMultipleTimesProperly() throws {
        throw XCTSkip("Test is failing intermittently on Bitrise")
//        let manager = createManager()
//        let configuration = createConfiguration()
//        addNumberOfTabs(manager: manager, configuration: configuration, tabNumber: 2)
//        XCTAssertEqual(manager.tabs.count, 2)
//
//        waitStoreChanges(manager: manager, managerTabCount: 2, profileTabCount: 2)
//
//        // Add 2 more tabs
//        addNumberOfTabs(manager: manager, configuration: configuration, tabNumber: 2)
//        XCTAssertEqual(manager.tabs.count, 4)
//
//        waitStoreChanges(manager: manager, managerTabCount: 4, profileTabCount: 4)
    }

    func testRemoveAndAddTab_doesntStoreRemovedTabs() throws {
        throw XCTSkip("Test is failing intermittently on Bitrise")
//        let manager = createManager()
//        let configuration = createConfiguration()
//        addNumberOfTabs(manager: manager, configuration: configuration, tabNumber: 2)
//        XCTAssertEqual(manager.tabs.count, 2)
//
//        // Remove all tabs, and add just 1 tab
//        manager.removeAll()
//        addTabWithSessionData(manager: manager, configuration: configuration)
//
//        waitStoreChanges(manager: manager, managerTabCount: 1, profileTabCount: 1)
    }
}

// MARK: - Helper methods
private extension TabManagerStoreTests {

    func createManager(file: StaticString = #file, line: UInt = #line) -> TabManager {
        let manager = TabManager(profile: profile, imageStore: nil)
        manager.testClearArchive()

        trackForMemoryLeaks(manager, file: file, line: line)
        return manager
    }

    func createConfiguration(file: StaticString = #file, line: UInt = #line) -> WKWebViewConfiguration {
        let configuration = WKWebViewConfiguration()
        configuration.processPool = WKProcessPool()
        configureiPad()

        trackForMemoryLeaks(configuration, file: file, line: line)
        return configuration
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

    func addNumberOfTabs(manager: TabManager, configuration: WKWebViewConfiguration, tabNumber: Int, isPrivate: Bool = false) {
        for _ in 0..<tabNumber {
            addTabWithSessionData(manager: manager, configuration: configuration, isPrivate: isPrivate)
        }
    }

    // Without session data, a Tab can't become a SavedTab and get archived
    func addTabWithSessionData(manager: TabManager, configuration: WKWebViewConfiguration, isPrivate: Bool = false) {
        let tab = Tab(bvc: BrowserViewController.foregroundBVC(), configuration: configuration, isPrivate: isPrivate)
        tab.url = URL(string: "http://yahoo.com")!
        manager.configureTab(tab, request: URLRequest(url: tab.url!), flushToDisk: false, zombie: false)
        tab.sessionData = SessionData(currentPage: 0, urls: [tab.url!], lastUsedTime: Date.now())
    }

    func waitStoreChanges(manager: TabManager, managerTabCount: Int, profileTabCount: Int, file: StaticString = #file, line: UInt = #line) {
        let expectation = expectation(description: "Manager stored changes")
        manager.storeChanges(writeCompletion: { [weak self] in
            guard let self = self else { XCTFail("self should be strong"); return }

            let managerMessage = "TestTabCountOnDisk is \(manager.testTabCountOnDisk()) when it should be \(managerTabCount)"
            XCTAssertEqual(manager.testTabCountOnDisk(), managerTabCount, managerMessage, file: file, line: line)

            let profileMessage = "NumberOfTabsStored is \(self.profile.numberOfTabsStored) when it should be \(profileTabCount)"
            XCTAssertEqual(self.profile.numberOfTabsStored, profileTabCount, profileMessage, file: file, line: line)
            expectation.fulfill()
        })

        waitForExpectations(timeout: 20) { error in
            if let error = error { XCTFail("WaitForExpectations failed with: \(error.localizedDescription)", file: file, line: line) }
        }
    }
}
