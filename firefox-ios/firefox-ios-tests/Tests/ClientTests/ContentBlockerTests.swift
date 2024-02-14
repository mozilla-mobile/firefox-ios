// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Client

final class ContentBlockerTests: XCTestCase {
    func testCompileListsNotInStore_callsCompletionHandlerSuccessfully() {
        ensureAllRulesAreRemovedFromStore()
        let excpectation = XCTestExpectation()
        ContentBlocker.shared.compileListsNotInStore {
            excpectation.fulfill()
        }
        wait(for: [excpectation])
    }

    private func ensureAllRulesAreRemovedFromStore() {
        let expectation = XCTestExpectation()
        ContentBlocker.shared.removeAllRulesInStore {
            expectation.fulfill()
        }
        wait(for: [expectation])
    }
}
