// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
@testable import Client

import XCTest

class QuickActionsTest: XCTestCase {

    private var browserViewController: SpyBrowserViewController!
    private var quickActions: QuickActions!
    private var profile: TabManagerMockProfile!
    private var tabManager: TabManager!

    override func setUp() {
        super.setUp()
        profile = TabManagerMockProfile()
        tabManager = TabManager(profile: profile, imageStore: nil)
        browserViewController = SpyBrowserViewController(profile: profile, tabManager: tabManager)
        browserViewController.addSubviews()
        quickActions = QuickActions.sharedInstance
    }

    override func tearDown() {
        super.tearDown()
        profile = nil
        tabManager = nil
        browserViewController = nil
        quickActions = nil
    }

    func testNewTabShortcut() {
        let expectation = expectation(description: "New tab is opened")
        browserViewController.handleOpenNewTab = {
            XCTAssertTrue(self.browserViewController.openedUrlFromExternalSource,
                          "openedUrlFromExternalSource needs to be true for start at home feature")
            expectation.fulfill()
        }

        let shortcutItem = UIApplicationShortcutItem(type: ShortcutType.newTab.rawValue, localizedTitle: "")
        quickActions.handleShortCutItem(shortcutItem, withBrowserViewController: browserViewController)
        waitForExpectations(timeout: 5, handler: nil)
    }

    func testNewPrivateTabShortcut() {
        let expectation = expectation(description: "New private tab is opened")
        browserViewController.handleOpenNewTab = {
            XCTAssertTrue(self.browserViewController.openedUrlFromExternalSource,
                          "openedUrlFromExternalSource needs to be true for start at home feature")
            expectation.fulfill()
        }

        let shortcutItem = UIApplicationShortcutItem(type: ShortcutType.newPrivateTab.rawValue, localizedTitle: "")
        quickActions.handleShortCutItem(shortcutItem, withBrowserViewController: browserViewController)
        waitForExpectations(timeout: 5, handler: nil)
    }

    func testOpenBookmark() {
        let expectation = expectation(description: "Last bookmark is opened")
        browserViewController.handleOpenURL = {
            XCTAssertTrue(self.browserViewController.openedUrlFromExternalSource,
                          "openedUrlFromExternalSource needs to be true for start at home feature")
            expectation.fulfill()
        }

        let shortcutItem = BookmarkShortcutItem()
        quickActions.handleShortCutItem(shortcutItem, withBrowserViewController: browserViewController)
        waitForExpectations(timeout: 5, handler: nil)
    }
}

// MARK: - Helper methods

private class BookmarkShortcutItem: UIApplicationShortcutItem {
    convenience init() {
        self.init(type: ShortcutType.openLastBookmark.rawValue, localizedTitle: "")
    }

    override var userInfo: [String : NSSecureCoding]? {
        return [QuickActions.TabURLKey: "https://www.mozilla.org/en-CA/" as NSSecureCoding]
    }
}

private class SpyBrowserViewController: BrowserViewController {
    var handleOpenNewTab: (() -> Void)?
    var handleOpenURL: (() -> Void)?

    override func openBlankNewTab(focusLocationField: Bool, isPrivate: Bool = false, searchFor searchText: String? = nil) {
        super.openBlankNewTab(focusLocationField: focusLocationField, isPrivate: isPrivate, searchFor: searchText)
        handleOpenNewTab?()
    }

    override func switchToTabForURLOrOpen(_ url: URL, isPrivate: Bool = false) {
        super.switchToTabForURLOrOpen(url, isPrivate: isPrivate)
        handleOpenURL?()
    }
}
