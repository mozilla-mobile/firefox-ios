/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import XCTest
@testable import Shared

class FSUtilsTests: XCTestCase {
    func testListOpenFileDescriptors() {
        let tempA = "\(NSTemporaryDirectory())A.tmp"
        let tempB = "\(NSTemporaryDirectory())B.tmp"
        let tempC = "\(NSTemporaryDirectory())C.tmp"

        var openDescriptors = FSUtils.openFileDescriptors()
        let prevCount = openDescriptors.keys.count

        // Open up some file descriptors
        let fdA = open(tempA, O_RDWR | O_CREAT)
        let fdB = open(tempB, O_RDWR | O_CREAT)
        let fdC = open(tempC, O_RDWR | O_CREAT)

        openDescriptors = FSUtils.openFileDescriptors()
        XCTAssertEqual(openDescriptors.keys.count, prevCount + 3)

        close(fdA)
        close(fdB)
        close(fdC)

        openDescriptors = FSUtils.openFileDescriptors()
        XCTAssertEqual(openDescriptors.keys.count, prevCount)
    }
}
