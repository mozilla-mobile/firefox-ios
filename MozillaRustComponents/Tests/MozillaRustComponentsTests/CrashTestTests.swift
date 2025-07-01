/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

@testable import MozillaRustComponents
@testable import MozillaAppServices
import XCTest

class CrashTestTests: XCTestCase {
    override func setUp() {
        // This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // This method is called after the invocation of each test method in the class.
    }

    func testErrorsAreThrown() {
        XCTAssertThrowsError(try triggerRustError())
    }

    // We can't test `triggerRustAbort()` here because it's a hard crash.

    // We can't test `triggerRustPanic()` here because it fails in a `try!` and crashes.
}
