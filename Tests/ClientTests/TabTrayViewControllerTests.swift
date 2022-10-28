// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

@testable import Client

import XCTest
import WebKit

class TabTrayViewControllerTests: XCTestCase {

    var profile: TabManagerMockProfile!
    var manager: TabManager!
    var tabTray: TabTrayViewController!
    var gridTab: GridTabViewController!

    override func setUp() {
        super.setUp()

        profile = TabManagerMockProfile()
        manager = TabManager(profile: profile, imageStore: nil)
        tabTray = TabTrayViewController(tabTrayDelegate: nil, profile: profile, tabToFocus: nil, tabManager: manager)
        gridTab = GridTabViewController(tabManager: manager, profile: profile)
        manager.addDelegate(gridTab)
    }

    override func tearDown() {
        super.tearDown()

        profile = nil
        manager = nil
        tabTray = nil
        gridTab = nil
    }

    func testCountUpdatesAfterTabRemoval() {
        let tabToRemove = manager.addTab()
        manager.addTab()

        XCTAssertEqual(tabTray.viewModel.normalTabsCount, "2")
        XCTAssertEqual(tabTray.countLabel.text, "2")

        // Wait for notification of .TabClosed when tab is removed
        weak var expectation = self.expectation(description: "notificationReceived")
        NotificationCenter.default.addObserver(forName: .UpdateLabelOnTabClosed, object: nil, queue: nil) { notification in
            expectation?.fulfill()
        }
        manager.removeTab(tabToRemove)
        waitForExpectations(timeout: 1.0, handler: nil)

        XCTAssertEqual(tabTray.viewModel.normalTabsCount, "1")
        XCTAssertEqual(tabTray.countLabel.text, "1")
    }

    func testRemoveAllTabs_AndClearCookies() {
        // Open 2 tabs for testing that tabs closed
        _ = manager.addTab()
        _ = manager.addTab()
        let dataTypes = Set([WKWebsiteDataTypeCookies, WKWebsiteDataTypeLocalStorage, WKWebsiteDataTypeSessionStorage, WKWebsiteDataTypeWebSQLDatabases, WKWebsiteDataTypeIndexedDBDatabases])
        var cookieCount = 0
        var tabCount = tabTray.viewModel.normalTabsCount

        XCTAssertTrue(tabCount == "2", "2 Tabs were not opened")

        // Add a cookie to Cookie Store
        let expectation1 = self.expectation(description: "setCookie")
        WKWebsiteDataStore.default().httpCookieStore.setCookie(HTTPCookie(properties: [
            .domain: "https://mozilla.org",
            .path: "/",
            .name: "TestCookie",
            .value: "TestCookieValue",
            .secure: "TRUE",
            .expires: NSDate(timeIntervalSinceNow: 31556926)
        ])!) {
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 5)

        // Check that Cookie is added
        let expectation2 = self.expectation(description: "checkCookie1")
        WKWebsiteDataStore.default().fetchDataRecords(ofTypes: dataTypes) { records in
            cookieCount = records.count

            XCTAssertTrue((cookieCount > 0), "Initial Cookie Count is Zero")

            expectation2.fulfill()
        }
        wait(for: [expectation2], timeout: 5)

        self.gridTab.closeTabsTrayBackground(removeCookies: true)

        // Wait for notification that tabs have been closed
        let expectation3 = self.expectation(description: "didCloseNotificationReceived")
        NotificationCenter.default.addObserver(forName: .TabsTrayDidClose, object: nil, queue: nil) { notification in
            expectation3.fulfill()
        }
        wait(for: [expectation3], timeout: 5)

        // Check that cookie is removed
        let expectation4 = self.expectation(description: "checkCookie2")
        WKWebsiteDataStore.default().fetchDataRecords(ofTypes: dataTypes) { records in
            cookieCount = records.count
            XCTAssertTrue((cookieCount == 0), "Cookies were not cleared")
            expectation4.fulfill()
        }
        wait(for: [expectation4], timeout: 5)

        // Check that tabs have been cleared
        tabCount = self.tabTray.viewModel.normalTabsCount
        XCTAssertTrue(tabCount == "1", "Tabs are not cleared")
    }

    func testRemoveAllTabs_WithoutClearingCookies() {
        // Open 2 tabs for testing that tabs closed
        _ = manager.addTab()
        _ = manager.addTab()
        let dataTypes = Set([WKWebsiteDataTypeCookies, WKWebsiteDataTypeLocalStorage, WKWebsiteDataTypeSessionStorage, WKWebsiteDataTypeWebSQLDatabases, WKWebsiteDataTypeIndexedDBDatabases])
        var cookieCount = 0
        var tabCount = tabTray.viewModel.normalTabsCount

        XCTAssertTrue(tabCount == "2", "2 Tabs were not opened")

        // Add a cookie to Cookie Store
        let expectation1 = self.expectation(description: "setCookie")
        WKWebsiteDataStore.default().httpCookieStore.setCookie(HTTPCookie(properties: [
            .domain: "https://mozilla.org",
            .path: "/",
            .name: "TestCookie",
            .value: "TestCookieValue",
            .secure: "TRUE",
            .expires: NSDate(timeIntervalSinceNow: 31556926)
        ])!) {
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 5)

        // Check that Cookie is added
        let expectation2 = self.expectation(description: "checkCookie1")
        WKWebsiteDataStore.default().fetchDataRecords(ofTypes: dataTypes) { records in
            cookieCount = records.count

            XCTAssertTrue((cookieCount > 0), "Initial Cookie Count is Zero")

            expectation2.fulfill()
        }
        wait(for: [expectation2], timeout: 5)

        self.gridTab.closeTabsTrayBackground()

        // Wait for notification that tabs have been closed
        let expectation3 = self.expectation(description: "didCloseNotificationReceived")
        NotificationCenter.default.addObserver(forName: .TabsTrayDidClose, object: nil, queue: nil) { notification in
            expectation3.fulfill()
        }
        wait(for: [expectation3], timeout: 5)

        // Check that cookie is NOT removed
        let expectation4 = self.expectation(description: "checkCookie2")
        WKWebsiteDataStore.default().fetchDataRecords(ofTypes: dataTypes) { records in
            cookieCount = records.count
            XCTAssertTrue((cookieCount > 0), "Cookies were cleared, and should not have been cleared")
            expectation4.fulfill()
        }
        wait(for: [expectation4], timeout: 5)

        // Check that tabs have been cleared
        tabCount = self.tabTray.viewModel.normalTabsCount
        XCTAssertTrue(tabCount == "1", "Tabs are not cleared")
    }
}
