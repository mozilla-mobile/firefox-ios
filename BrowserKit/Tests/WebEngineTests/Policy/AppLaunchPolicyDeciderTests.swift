// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import WebEngine

final class AppLaunchPolicyDeciderTests: XCTestCase {
    private var mockDecider: MockPolicyDecider!

    override func setUp() {
        super.setUp()
        mockDecider = MockPolicyDecider()
    }

    override func tearDown() {
        mockDecider = nil
        super.tearDown()
    }

    func testPolicyForPopupNavigation_returnsLaunchApp_forSupportedSchemes() {
        let subject = createSubject()
        let urls = SupportedAppScheme.allCases.map {
            URL(string: "\($0.rawValue)://test")!
        }
        let policies = urls.map {
            subject.policyForPopupNavigation(action: MockNavigationAction(url: $0))
        }

        policies.forEach {
            XCTAssertEqual($0, .launchExternalApp)
        }
    }

    func testPolicyForPopupNavigation_returnsLaunchApp_forSupportedHost() {
        let appStoreURL = URL(string: "https://itunes.apple.com")!
        let subject = createSubject()

        let policy = subject.policyForPopupNavigation(action: MockNavigationAction(url: appStoreURL))

        XCTAssertEqual(policy, .launchExternalApp)
    }

    func testPolicyForPopupNavigation_callsNext_forUnsupportedSchemes() {
        let subject = createSubject(next: mockDecider)
        let url = URL(string: "unsupported://test")!

        _ = subject.policyForPopupNavigation(action: MockNavigationAction(url: url))

        XCTAssertEqual(mockDecider.policyForPopupNavigationCalled, 1)
    }

    func testPolicyForPopupNavigation_returnsCancel_whenNextIsNil() {
        let subject = createSubject()

        let url = URL(string: "unsupported://test")!

        let policy = subject.policyForPopupNavigation(action: MockNavigationAction(url: url))

        XCTAssertEqual(policy, .cancel)
        XCTAssertEqual(mockDecider.policyForPopupNavigationCalled, 0)
    }

    private func createSubject(next: WKPolicyDecider? = nil) -> AppLaunchPolicyDecider {
        return AppLaunchPolicyDecider(nextDecider: next)
    }
}
