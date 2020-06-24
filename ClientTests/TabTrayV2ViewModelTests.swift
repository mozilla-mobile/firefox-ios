/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

@testable import Client

import WebKit
import XCTest

class TabTrayV2ViewModelTests: XCTestCase {
    var mockTabTrayViewController: MockTabTrayViewController!
    var mockTabManager: MockTabManager!
    var subject: TabTrayV2ViewModel!

    override func setUp() {
        super.setUp()
        mockTabTrayViewController = MockTabTrayViewController()
        mockTabManager = MockTabManager()
        subject = TabTrayV2ViewModel(
            viewController: mockTabTrayViewController,
            tabManager: mockTabManager
        )
    }

    func testAddsTabManagerDelegate() {
        XCTAssertEqual(subject, mockTabManager.tabManagerDelegateAdded as? TabTrayV2ViewModel)
    }

    func testSetupPrivateModeBadge() {
        XCTAssertFalse(mockTabTrayViewController.toolbar.maskButton.isSelected)
    }

    func testTogglePrivateMode() {
        XCTAssertFalse(subject.isInPrivateMode)
        subject.togglePrivateMode()
        XCTAssertTrue(subject.isInPrivateMode)
    }

    func testAddTab() {
        subject.addTab()
        XCTAssertTrue(mockTabManager.addTabCalled)
        XCTAssertFalse(mockTabManager.addTabPrivate)
    }

    func testAddPrivateTab() {
        subject.togglePrivateMode()
        subject.addPrivateTab()
        XCTAssertTrue(mockTabManager.addTabCalled)
        XCTAssertTrue(mockTabManager.addTabPrivate)
    }

    func testAddPrivateTabWhenNotInPrivateMode() {
        subject.addPrivateTab()
        XCTAssertFalse(mockTabManager.addTabCalled)
        XCTAssertFalse(mockTabManager.addTabPrivate)
    }
}

class MockTabTrayViewController: TabTrayV2ViewController {
}

class MockTabManager: TabManager {
    init() {
        super.init(profile: BrowserProfile(localName: "ln"), imageStore: nil)
    }

    var tabManagerDelegateAdded: TabManagerDelegate?
    override func addDelegate(_ delegate: TabManagerDelegate) {
        tabManagerDelegateAdded = delegate
    }

    var addTabCalled = false
    var addTabPrivate = false
    override func addTab(_ request: URLRequest! = nil, configuration: WKWebViewConfiguration! = nil, afterTab: Tab? = nil, isPrivate: Bool = false) -> Tab {
        addTabCalled = true
        addTabPrivate = isPrivate
        return super.addTab()
    }

    var selectTabCalled = false
    override func selectTab(_ tab: Tab?, previous: Tab? = nil) {
        selectTabCalled = true
    }
}
