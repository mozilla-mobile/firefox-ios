/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Shared
import Deferred
import XCTest

protocol Succeedable {
    var isSuccess: Bool { get }
    var isFailure: Bool { get }
}

extension Maybe: Succeedable {}

extension Deferred where T: Succeedable {
    func succeeded() {
        XCTAssertTrue(self.value.isSuccess)
    }

    func failed() {
        XCTAssertTrue(self.value.isFailure)
    }
}

