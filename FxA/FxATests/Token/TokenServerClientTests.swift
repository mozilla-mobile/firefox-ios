// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import XCTest
import FxA

class TokenServerClientTests: XCTestCase {
    func testAudienceForEndpoint() {
        // Sub-domains and path components.
        XCTAssertEqual("http://sub.test.com", TokenServerClient.getAudienceForEndpoint("http://sub.test.com"));
        XCTAssertEqual("http://test.com", TokenServerClient.getAudienceForEndpoint("http://test.com/"));
        XCTAssertEqual("http://test.com", TokenServerClient.getAudienceForEndpoint("http://test.com/path/component"));
        XCTAssertEqual("http://test.com", TokenServerClient.getAudienceForEndpoint("http://test.com/path/component/"));

        // No port and default port.
        XCTAssertEqual("http://test.com", TokenServerClient.getAudienceForEndpoint("http://test.com"));
        XCTAssertEqual("http://test.com:80", TokenServerClient.getAudienceForEndpoint("http://test.com:80"));

        XCTAssertEqual("https://test.com", TokenServerClient.getAudienceForEndpoint("https://test.com"));
        XCTAssertEqual("https://test.com:443", TokenServerClient.getAudienceForEndpoint("https://test.com:443"));

        // Ports that are the default ports for a different scheme.
        XCTAssertEqual("https://test.com:80", TokenServerClient.getAudienceForEndpoint("https://test.com:80"));
        XCTAssertEqual("http://test.com:443", TokenServerClient.getAudienceForEndpoint("http://test.com:443"));

        // Arbitrary ports.
        XCTAssertEqual("http://test.com:8080", TokenServerClient.getAudienceForEndpoint("http://test.com:8080"));
        XCTAssertEqual("https://test.com:4430", TokenServerClient.getAudienceForEndpoint("https://test.com:4430"));
    }
}
