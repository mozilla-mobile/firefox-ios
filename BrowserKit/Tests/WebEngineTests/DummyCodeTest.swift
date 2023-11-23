// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import WebEngine

final class DummyCodeTest: XCTestCase {
    func testDummyCode() throws {
        let subject = DummyCode()
        XCTAssertEqual(subject.foo, 1)
    }
}
