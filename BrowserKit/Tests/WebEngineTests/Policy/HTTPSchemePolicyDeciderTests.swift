// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import WebEngine

final class HTTPSchemePolicyDeciderTests: XCTestCase {
    private var mockDecider: MockPolicyDecider!

    override func setUp() {
        super.setUp()
        mockDecider = MockPolicyDecider()
    }

    override func tearDown() {
        mockDecider = nil
        super.tearDown()
    }

    

    private func createSubject(next: WKPolicyDecider? = nil) -> HTTPSchemePolicyDecider {
        return HTTPSchemePolicyDecider(next: next)
    }
}
