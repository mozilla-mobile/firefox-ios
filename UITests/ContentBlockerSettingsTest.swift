/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import EarlGrey
import Deferred
@testable import Client

class ContentBlockerSettingsTests: KIFTestCase {
    var tab: Tab!
    var delegate: AppDelegate!
    var testDone: XCTestExpectation!

    // A convenience function for static or instance usage.
    func tapInTable(_ label: String) {
        ContentBlockerSettingsTests.tapInTable(label)
    }

    class func tapInTable(_ label: String) {
        EarlGrey.select(elementWithMatcher:grey_accessibilityLabel(label)).using(searchAction: grey_scrollInDirection(GREYDirection.down, 600), onElementWithMatcher: grey_kindOfClass(UITableView.self)).perform(grey_tap())
    }

    override class func setUp() {
        super.setUp()
        // Called once before all tests are run
        BrowserUtils.dismissFirstRunUI()
        EarlGrey.select(elementWithMatcher: grey_accessibilityLabel("Menu")).perform(grey_tap())
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("SettingsMenuItem")).perform(grey_tap())
        tapInTable("Tracking Protection")
    }

    override class func tearDown() {
        let delegate = UIApplication.shared.delegate as! AppDelegate
        delegate.tabManager.removeAll()
    }

    override func setUp() {
        testDone = expectation(description: "wait for test")
        delegate = UIApplication.shared.delegate as! AppDelegate
        tab = delegate.tabManager.addTab()
    }

    @available(iOS 11, *)
    func testStrict() {
        let blocker = tab.contentBlocker as! ContentBlockerHelper
        tapInTable("Always On")
        tapInTable("Strict")
        blocker.addActiveRulesToTab().uponQueue(.main) { result in
            let list = blocker.blocklistStrict + blocker.blocklistBasic
            XCTAssert(result.sorted() == list.sorted())
            self.testDone.fulfill()
        }
        waitForExpectations(timeout: 5.0) { _ in }
    }

    @available(iOS 11, *)
    func testNever() {
        let blocker = tab.contentBlocker as! ContentBlockerHelper
        tapInTable("Never")
        blocker.addActiveRulesToTab().uponQueue(.main) { result in
            XCTAssert(result.count < 1)
            self.testDone.fulfill()
        }
        waitForExpectations(timeout: 5.0) { _ in }
    }

    @available(iOS 11, *)
    func testPrivateModeOnly() {
        let blocker = tab.contentBlocker as! ContentBlockerHelper
        tapInTable("Private Browsing Mode Only")
        tapInTable("Basic (Recommended)")
        
        let _ = blocker.addActiveRulesToTab().bindQueue(.main) { result -> Deferred<Void> in
            XCTAssert(result.count < 1)
            return Deferred(value: ())
        }.bindQueue(.main) { result -> Deferred<[String]> in
            let tab = self.delegate.tabManager.addTab(isPrivate: true)
            let blocker = tab.contentBlocker as! ContentBlockerHelper
            return blocker.addActiveRulesToTab()
        }.uponQueue(.main) { result in
            XCTAssert(result.sorted() == blocker.blocklistBasic.sorted())
            self.testDone.fulfill()
        }
        waitForExpectations(timeout: 5.0) { _ in }
    }
}

