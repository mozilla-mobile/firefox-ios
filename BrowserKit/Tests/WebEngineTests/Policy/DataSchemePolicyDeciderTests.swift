// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import WebEngine

final class DataSchemePolicyDeciderTests: XCTestCase {
    private var mockDecider: MockPolicyDecider!

    override func setUp() {
        super.setUp()
        mockDecider = MockPolicyDecider()
    }

    override func tearDown() {
        mockDecider = nil
        super.tearDown()
    }

    func testPolicyForPopupNavigation_allowsImageDataScheme_whenTargetIsMainFrame() {
        let subject = createSubject()
        let url = URL(string: "data:image/test-image")!

        let policy = subject.policyForPopupNavigation(action: MockNavigationAction(url: url))

        XCTAssertEqual(policy, .allow)
    }

    func testPolicyForPopupNavigation_allowsVideoDataScheme_whenTargetIsMainFrame() {
        let subject = createSubject()
        let url = URL(string: "data:video/test-video")!

        let policy = subject.policyForPopupNavigation(action: MockNavigationAction(url: url))

        XCTAssertEqual(policy, .allow)
    }

    func testPolicyForPopupNavigation_allowsPDFDataScheme_whenTargetIsMainFrame() {
        let subject = createSubject()
        let url = URL(string: "data:application/pdf/test")!

        let policy = subject.policyForPopupNavigation(action: MockNavigationAction(url: url))

        XCTAssertEqual(policy, .allow)
    }

    func testPolicyForPopupNavigation_allowsJSONDataScheme_whenTargetIsMainFrame() {
        let subject = createSubject()
        let url = URL(string: "data:application/json/test")!

        let policy = subject.policyForPopupNavigation(action: MockNavigationAction(url: url))

        XCTAssertEqual(policy, .allow)
    }

    func testPolicyForPopupNavigation_allowsBase64DataScheme_whenTargetIsMainFrame() {
        let subject = createSubject()
        let url = URL(string: "data:;base64,")!

        let policy = subject.policyForPopupNavigation(action: MockNavigationAction(url: url))

        XCTAssertEqual(policy, .allow)
    }

    func testPolicyForPopupNavigation_preventsOtherDataSchemes_whenTargetIsMainFrame() {
        let subject = createSubject()
        let url = URL(string: "unsupported:scheme")!

        let policy = subject.policyForPopupNavigation(action: MockNavigationAction(url: url))

        XCTAssertEqual(policy, .cancel)
    }

    func testPolicyForPopupNavigation_CancelAnyScheme_whenTargetIsNotMainFrame() {
        let subject = createSubject()
        let url = URL(string: "data:video/")!

        let policy = subject.policyForPopupNavigation(action: MockNavigationAction(url: url, isMainFrame: false))

        XCTAssertEqual(policy, .cancel)
    }

    func testPolicyForPopupNavigation_forwardsToNextDecider_whenTargetIsNotMainFrame() {
        let subject = createSubject(next: mockDecider)
        let url = URL(string: "data:video/")!

        _ = subject.policyForPopupNavigation(action: MockNavigationAction(url: url, isMainFrame: false))

        XCTAssertEqual(mockDecider.policyForPopupNavigationCalled, 1)
    }

    func testPolicyForPopupNavigation_forwardsToNextDecider_whenSchemeIsNotHandled() {
        let subject = createSubject(next: mockDecider)
        let url = URL(string: "unsupported:scheme")!

        _ = subject.policyForPopupNavigation(action: MockNavigationAction(url: url))

        XCTAssertEqual(mockDecider.policyForPopupNavigationCalled, 1)
    }

    func testPolicyForPopupNavigation_doesntForwardToNextDecider_whenSchemeIsHandled() {
        let subject = createSubject(next: mockDecider)
        let url = URL(string: "data:video/")!

        let policy = subject.policyForPopupNavigation(action: MockNavigationAction(url: url))

        XCTAssertEqual(mockDecider.policyForPopupNavigationCalled, 0)
        XCTAssertEqual(policy, .allow)
    }

    private func createSubject(next: WKPolicyDecider? = nil) -> DataSchemePolicyDecider {
        return DataSchemePolicyDecider(nextDecider: next)
    }
}
