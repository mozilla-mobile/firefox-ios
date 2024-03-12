// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import ContentBlockingGenerator

final class TempTest: XCTestCase {
    func testFoo() {
        let subject = Temp()
        XCTAssertEqual(subject.foo, 1)
    }
}
