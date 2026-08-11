// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Shared
@testable import Client

final class EcosiaInAppWebViewUserAgentTests: XCTestCase {

    func testMobileUserAgent_matchesDefaultEcosiaMobileUserAgent() {
        // Given / When
        let userAgent = EcosiaInAppWebViewUserAgent.mobileUserAgent()

        // Then
        XCTAssertEqual(
            userAgent,
            UserAgentBuilder.defaultMobileUserAgent().userAgent()
        )
    }

    func testMobileUserAgent_identifiesAsEcosiaIOSApp() {
        // Given / When
        let userAgent = EcosiaInAppWebViewUserAgent.mobileUserAgent()

        // Then
        XCTAssertTrue(
            userAgent.contains(UserAgent.uaBitEcosia),
            "In-app web views must identify as the Ecosia iOS app so web content can adjust its UI."
        )
    }
}
