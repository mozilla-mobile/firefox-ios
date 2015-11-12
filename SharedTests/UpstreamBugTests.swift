/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import XCTest

class UpstreamBugTests: XCTestCase {
    // This crashes in release builds in Xcode 7.1.
    // https://forums.developer.apple.com/thread/23455
    func testSortInPlace() {
        var arr = [["abc"], ["def"]]
        arr.sortInPlace({ $0[0] < $1[0] })
    }
}