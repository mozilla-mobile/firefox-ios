/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

@testable import MozillaRustComponents
@testable import MozillaAppServices

import Glean
import XCTest
import MozillaAppServices

class LoginsTests: XCTestCase {
    var storage: LoginsStorage!

    override func setUp() {
        super.setUp()
        Glean.shared.resetGlean(clearStores: true)
    }

    override func tearDown() {
        // This method is called after the invocation of each test method in the class.
    }
}
