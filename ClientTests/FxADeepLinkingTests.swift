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
    var expectUrl = URL(string: "https://accounts.firefox.com/signin?service=sync&context=fx_ios_v1&signin=test&another=one")
    
    override func setUp() {
        super.setUp()
        self.profile = MockProfile()
    }
    
    func testLaunchWithNilOptions() {
        self.vc = FxAContentViewController(profile: self.profile)
        self.vc.viewDidLoad()
        XCTAssertEqual(self.vc.url, self.vc.profile.accountConfiguration.signInURL)
        
        self.vc = FxAContentViewController(profile: self.profile, fxaOptions: nil)
        self.vc.viewDidLoad()
        XCTAssertEqual(self.vc.url, self.vc.profile.accountConfiguration.signInURL)
    }
    
    func testLaunchWithOptions() {
        let url = URL(string: "firefox://fxa-signin?signin=test&another=one")
        let query = url!.getQuery()
        let fxaOptions = FxALaunchParams(query: query)
        self.vc = FxAContentViewController(profile: self.profile, fxaOptions: fxaOptions)
        self.vc.viewDidLoad()
        XCTAssertEqual(self.vc.url, expectUrl!)
    }
    
    func testDoesntOverrideServiceContext() {
        let url = URL(string: "firefox://fxa-signin?service=asdf&context=123&signin=test&another=one")
        let query = url!.getQuery()
        let fxaOptions = FxALaunchParams(query: query)
        self.vc = FxAContentViewController(profile: self.profile, fxaOptions: fxaOptions)
        self.vc.viewDidLoad()
        XCTAssertEqual(self.vc.url, expectUrl!)
    }
}
