// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Client

final class ContentBlockerTests: XCTestCase {
    override func setUp() {
        super.setUp()
        ensureAllRulesAreRemovedFromStore()
    }

    private func ensureAllRulesAreRemovedFromStore() {
        let expectation = XCTestExpectation()
        ContentBlocker.shared.removeAllRulesInStore {
            expectation.fulfill()
        }
        wait(for: [expectation])
    }

    func testCompileListsNotInStore_callsCompletionHandlerSuccessfully() {
        let expectation = XCTestExpectation()
        ContentBlocker.shared.compileListsNotInStore {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 5.0)
    }
}
