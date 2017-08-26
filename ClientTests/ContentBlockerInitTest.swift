/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import GCDWebServers
import XCTest
import WebKit
@testable import Client

class ContentBlockerInitTest: XCTestCase {
    @available(iOS 11, *)
    func testInit() {
        let tab = Tab(configuration: WKWebViewConfiguration())
        let profile = TabManagerMockProfile()
        let expect = expectation(description: "content blocker compiled lists")
        let cb = ContentBlockerHelper(tab: tab, profile: profile)
        cb.removeAllRulesInStore {
            cb.compileListsNotInStore { success in
                XCTAssert(success)
                expect.fulfill()
            }
        }
        waitForExpectations(timeout: 10, handler: nil)
    }
}
