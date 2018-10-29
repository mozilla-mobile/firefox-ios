/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

@testable import Client
import UIKit
import WebKit
import XCTest

class TabDisplayManagerTests: XCTestCase {
    let configuration = WKWebViewConfiguration()

    var bvc: BrowserViewController {
        return (UIApplication.shared.delegate as! AppDelegate).browserViewController
    }

    var displayManager: TabDisplayManager {
        return bvc.topTabsViewController!.test_getDisplayManager()
    }

    var tabManager: TabManager {
        return bvc.tabManager
    }

    // Without session data, a Tab can't become a SavedTab and get archived
    func addTab(isPrivate: Bool = false) -> Tab {
        let tab = Tab(configuration: configuration, isPrivate: isPrivate)
        tabManager.configureTab(tab, request: nil, flushToDisk: false, zombie: false)
        return tab
    }

    func testIsDraggingBecomesFalse() {
        if !bvc.urlBar.topTabsIsShowing {
            // this test is for iPad-only as it requires the tab display manager to be showing
            return
        }

        displayManager.test_toggleIsDragging()
        let tab = addTab()
        XCTAssertFalse(displayManager.test_getIsDragging())

        displayManager.test_toggleIsDragging()
        tabManager.selectTab(tab)
        XCTAssertFalse(displayManager.test_getIsDragging())

        displayManager.test_toggleIsDragging()
        tabManager.removeTabs([tab])
        XCTAssertFalse(displayManager.test_getIsDragging())
    }
}
