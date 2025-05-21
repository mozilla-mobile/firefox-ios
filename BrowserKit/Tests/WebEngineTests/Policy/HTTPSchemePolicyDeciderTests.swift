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

    func testPolicyForPopupNavigation_allowsHttpScheme() {
        let subject = createSubject()
        let url = URL(string: "http://example.com")!

        let policy = subject.policyForPopupNavigation(action: MockNavigationAction(url: url))

        XCTAssertEqual(policy, .allow)
    }

    func testPolicyForPopupNavigation_allowsHttpsScheme() {
        let subject = createSubject()
        let url = URL(string: "https://example.com")!

        let policy = subject.policyForPopupNavigation(action: MockNavigationAction(url: url))

        XCTAssertEqual(policy, .allow)
    }

    func testPolicyForPopupNavigation_allowsAboutScheme() {
        let subject = createSubject()
        let url = URL(string: "about://example.com")!

        let policy = subject.policyForPopupNavigation(action: MockNavigationAction(url: url))

        XCTAssertEqual(policy, .allow)
    }

    func testPolicyForPopupNavigation_allowsJavascriptScheme() {
        let subject = createSubject()
        let url = URL(string: "javascript://example.com")!

        let policy = subject.policyForPopupNavigation(action: MockNavigationAction(url: url))

        XCTAssertEqual(policy, .allow)
    }

    func testPolicyForPopupNavigation_blockPayPalPopup() {
        let subject = createSubject()
        let url = URL(string: "https://www.paypal.com")!

        let policy = subject.policyForPopupNavigation(action: MockNavigationAction(url: url))

        XCTAssertEqual(policy, .cancel)
    }

    func testPolicyForPopupNavigation_blockUnsupportedScheme() {
        let subject = createSubject()
        let url = URL(string: "itms-apps://test-app")!

        let policy = subject.policyForPopupNavigation(action: MockNavigationAction(url: url))

        XCTAssertEqual(policy, .cancel)
    }

    func testPolicyForPopupNavigation_forwardsToNextDecider_whenSchemeIsUnsupported() {
        let subject = createSubject(next: mockDecider)
        let url = URL(string: "itms-apps://test-app")!

        _ = subject.policyForPopupNavigation(action: MockNavigationAction(url: url))

        XCTAssertEqual(mockDecider.policyForPopupNavigationCalled, 1)
    }

    private func createSubject(next: WKPolicyDecider? = nil) -> HTTPSchemePolicyDecider {
        return HTTPSchemePolicyDecider(nextDecider: next)
    }
}
