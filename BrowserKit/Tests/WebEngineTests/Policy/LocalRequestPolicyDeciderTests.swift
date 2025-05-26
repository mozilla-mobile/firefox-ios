// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import WebEngine

final class LocalRequestPolicyDeciderTests: XCTestCase {
    private var mockDecider: MockPolicyDecider!

    override func setUp() {
        super.setUp()
        mockDecider = MockPolicyDecider()
    }

    override func tearDown() {
        mockDecider = nil
        super.tearDown()
    }

    func testPolicyForPopupNavigation_blockUnprivilegedLocalRequest() {
        let subject = createSubject()
        let url = URL(string: "internal://request?foo=bar")!

        let policy = subject.policyForPopupNavigation(action: MockNavigationAction(url: url))

        XCTAssertEqual(policy, .cancel)
    }

    func testPolicyForPopupNavigation_blockUnsupportedScheme() {
        let subject = createSubject()
        let url = URL(string: "https://example.com")!

        let policy = subject.policyForPopupNavigation(action: MockNavigationAction(url: url))

        XCTAssertEqual(policy, .cancel)
    }

    func testPolicyForPopupNavigation_forwardsUnsupportedSchemeToNextDecider() {
        let subject = createSubject(next: mockDecider)
        let url = URL(string: "https://example.com")!

        _ = subject.policyForPopupNavigation(action: MockNavigationAction(url: url))

        XCTAssertEqual(mockDecider.policyForPopupNavigationCalled, 1)
    }

    func testPolicyForPopupNavigation_allowsAuthorizedLocalScheme() {
        let subject = createSubject()
        let url = URL(string: "internal://request?uuidkey=\(WKInternalURL.uuid)")!

        let policy = subject.policyForPopupNavigation(action: MockNavigationAction(url: url))

        XCTAssertEqual(policy, .allow)
    }

    private func createSubject(next: WKPolicyDecider? = nil) -> LocalRequestPolicyDecider {
        return LocalRequestPolicyDecider(nextDecider: next)
    }
}
