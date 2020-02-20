/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

@testable import Account
import FxA
import Shared
import UIKit

import XCTest

private let ProductionTokenServerEndpointURL = URL(string: "https://token.services.mozilla.com/1.0/sync/1.5")!

// Testing client state is so delicate that I'm not going to test this.  The test below does two
// requests; we would need a third, and a guarantee of the server state, to test this completely.
// The rule is: if you turn up with a never-before-seen client state; you win.  If you turn up with
// a seen-before client state, you lose.
class TokenServerClientTests: LiveAccountTest {
    func testErrorOutput() {
        // Make sure we don't hide error details.
        let error = NSError(domain: "test", code: 123, userInfo: nil)
        XCTAssertEqual(
            "<TokenServerError.Local Error Domain=test Code=123 \"The operation couldn’t be completed. (test error 123.)\">",
            TokenServerError.local(error).description)
    }

    func testAudienceForEndpoint() {
        func audienceFor(_ endpoint: String) -> String {
            return TokenServerClient.getAudience(forURL: URL(string: endpoint)!)
        }

        // Sub-domains and path components.
        XCTAssertEqual("http://sub.test.com", audienceFor("http://sub.test.com"))
        XCTAssertEqual("http://test.com", audienceFor("http://test.com/"))
        XCTAssertEqual("http://test.com", audienceFor("http://test.com/path/component"))
        XCTAssertEqual("http://test.com", audienceFor("http://test.com/path/component/"))

        // No port and default port.
        XCTAssertEqual("http://test.com", audienceFor("http://test.com"))
        XCTAssertEqual("http://test.com:80", audienceFor("http://test.com:80"))

        XCTAssertEqual("https://test.com", audienceFor("https://test.com"))
        XCTAssertEqual("https://test.com:443", audienceFor("https://test.com:443"))

        // Ports that are the default ports for a different scheme.
        XCTAssertEqual("https://test.com:80", audienceFor("https://test.com:80"))
        XCTAssertEqual("http://test.com:443", audienceFor("http://test.com:443"))

        // Arbitrary ports.
        XCTAssertEqual("http://test.com:8080", audienceFor("http://test.com:8080"))
        XCTAssertEqual("https://test.com:4430", audienceFor("https://test.com:4430"))
    }
}
