/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import XCTest

class FailFastTestCase: XCTestCase {
    // This is how to make an assertion failure stop the current test function
    // but continue with other test functions in the same test case.
    // See http://stackoverflow.com/a/27016786/22003
    override func invokeTest() {
        self.continueAfterFailure = false
        defer { self.continueAfterFailure = true }
        super.invokeTest()
    }
}
