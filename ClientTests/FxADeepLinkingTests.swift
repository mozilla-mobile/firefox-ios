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

    override func tearDown() {
        self.profile._shutdown()
        super.tearDown()
    }

}
