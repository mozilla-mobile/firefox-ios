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

    func testNewTabShortcut_externalSourceIsTrue() {
        let shortcutItem = UIApplicationShortcutItem(type: ShortcutType.newTab.rawValue, localizedTitle: "")
        handleShortcutAndWait(shortcutItem: shortcutItem)
    }

    func testNewPrivateTabShortcut_externalSourceIsTrue() {
        let shortcutItem = UIApplicationShortcutItem(type: ShortcutType.newPrivateTab.rawValue, localizedTitle: "")
        handleShortcutAndWait(shortcutItem: shortcutItem)
    }

    func testOpenBookmarkShortcut_externalSourceIsTrue() {
        let shortcutItem = BookmarkShortcutItem()
        handleShortcutAndWait(shortcutItem: shortcutItem)
    }
}

// MARK: - Helper methods

private extension QuickActionsTest {
    /// Wait for openedUrlFromExternalSource to be set true, testing the start at home edge case
    func handleShortcutAndWait(shortcutItem: UIApplicationShortcutItem) {
        let expectation = expectation(description: "Completion URL of SpyBrowserViewController should be called")
        browserViewController.completionURL = {
            XCTAssertTrue(self.browserViewController.openedUrlFromExternalSource, "openedUrlFromExternalSource needs to be true for start at home feature")
            expectation.fulfill()
        }

        quickActions.handleShortCutItem(shortcutItem, withBrowserViewController: browserViewController)
        waitForExpectations(timeout: 5, handler: nil)
    }
}

private class BookmarkShortcutItem: UIApplicationShortcutItem {
    convenience init() {
        self.init(type: ShortcutType.openLastBookmark.rawValue, localizedTitle: "")
    }

    override var userInfo: [String : NSSecureCoding]? {
        return [QuickActions.TabURLKey: "https://www.mozilla.org/en-CA/" as NSSecureCoding]
    }
}

private class SpyBrowserViewController: BrowserViewController {
    var completionURL: (() -> Void)?

    override func openBlankNewTab(focusLocationField: Bool, isPrivate: Bool = false, searchFor searchText: String? = nil) {
        super.openBlankNewTab(focusLocationField: focusLocationField, isPrivate: isPrivate, searchFor: searchText)
        completionURL?()
    }

    override func switchToTabForURLOrOpen(_ url: URL, uuid: String? = nil, isPrivate: Bool = false) {
        super.switchToTabForURLOrOpen(url, uuid: uuid, isPrivate: isPrivate)
        completionURL?()
    }
}
