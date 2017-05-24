/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import XCTest
@testable import Client
import Shared

class FxADeepLinkingTests: XCTestCase {
    var profile: MockProfile!
    var vc: FxAContentViewController!
    var expectUrl = URL(string: "https://accounts.firefox.com/signin?service=sync&context=fx_ios_v1&signin=test&utm_source=somesource&entrypoint=one")
    
    override func setUp() {
        super.setUp()
        self.profile = MockProfile()
        self.vc = FxAContentViewController(profile: self.profile)
    }
    
    func testLaunchWithNilOptions() {
        let testUrl = self.vc.FxAURLWithOptions(nil)
        // Should use default urls for nil options
        XCTAssertEqual(testUrl, self.vc.profile.accountConfiguration.signInURL)
    }
    
    func testLaunchWithOptions() {
        let url = URL(string: "firefox://fxa-signin?signin=test&utm_source=somesource&entrypoint=one&ignore=this")
        let query = url!.getQuery()
        let fxaOptions = FxALaunchParams(query: query)
        let testUrl = self.vc.FxAURLWithOptions(fxaOptions)
        XCTAssertEqual(testUrl, expectUrl!)
    }
    
    func testDoesntOverrideServiceContext() {
        let url = URL(string: "firefox://fxa-signin?service=asdf&context=123&signin=test&entrypoint=one&utm_source=somesource&ignore=this")
        let query = url!.getQuery()
        let fxaOptions = FxALaunchParams(query: query)
        let testUrl = self.vc.FxAURLWithOptions(fxaOptions)
        XCTAssertEqual(testUrl, expectUrl!)
    }
}
