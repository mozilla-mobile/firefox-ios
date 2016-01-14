/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

@testable import Account
import Foundation
import FxA
import UIKit

import XCTest

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
            TokenServerError.Local(error).description)
    }

    func testAudienceForEndpoint() {
        func audienceFor(endpoint: String) -> String {
            return TokenServerClient.getAudienceForURL(NSURL(string: endpoint)!)
        }

        // Sub-domains and path components.
        XCTAssertEqual("http://sub.test.com", audienceFor("http://sub.test.com"));
        XCTAssertEqual("http://test.com", audienceFor("http://test.com/"));
        XCTAssertEqual("http://test.com", audienceFor("http://test.com/path/component"));
        XCTAssertEqual("http://test.com", audienceFor("http://test.com/path/component/"));

        // No port and default port.
        XCTAssertEqual("http://test.com", audienceFor("http://test.com"));
        XCTAssertEqual("http://test.com:80", audienceFor("http://test.com:80"));

        XCTAssertEqual("https://test.com", audienceFor("https://test.com"));
        XCTAssertEqual("https://test.com:443", audienceFor("https://test.com:443"));

        // Ports that are the default ports for a different scheme.
        XCTAssertEqual("https://test.com:80", audienceFor("https://test.com:80"));
        XCTAssertEqual("http://test.com:443", audienceFor("http://test.com:443"));

        // Arbitrary ports.
        XCTAssertEqual("http://test.com:8080", audienceFor("http://test.com:8080"));
        XCTAssertEqual("https://test.com:4430", audienceFor("https://test.com:4430"));
    }

    func testTokenSuccess() {
        let audience = TokenServerClient.getAudienceForURL(ProductionSync15Configuration().tokenServerEndpointURL)

        withCertificate { expectation, emailUTF8, keyPair, certificate in
            let assertion = JSONWebTokenUtils.createAssertionWithPrivateKeyToSignWith(keyPair.privateKey,
                certificate: certificate, audience: audience)

            let client = TokenServerClient()
            client.token(assertion).upon { result in
                if let token = result.successValue {
                    XCTAssertNotNil(token.id)
                    XCTAssertNotNil(token.key)
                    XCTAssertNotNil(token.api_endpoint)
                    XCTAssertTrue(token.uid >= 0)
                    XCTAssertTrue(token.api_endpoint.hasSuffix(String(token.uid)))
                    XCTAssertTrue(token.remoteTimestamp >= 1429121686000) // Not a special timestamp; just a sanity check.
                } else {
                    XCTAssertEqual(result.failureValue!.description, "")
                }
                expectation.fulfill()
            }
        }
        self.waitForExpectationsWithTimeout(100, handler: nil)
    }

    func testTokenFailure() {
        withVerifiedAccount { _, _ in
            // Account details aren't used, but we want to skip when we're not running live tests.
            let e = self.expectationWithDescription("")

            let assertion = "BAD ASSERTION"

            let client = TokenServerClient()
            client.token(assertion).upon { result in
                if let token = result.successValue {
                    XCTFail("Got token: \(token)")
                } else {
                    if let error = result.failureValue as? TokenServerError {
                        switch error {
                        case let .Remote(code, status, remoteTimestamp):
                            XCTAssertEqual(code, Int32(401)) // Bad auth.
                            XCTAssertEqual(status!, "error")
                            XCTAssertFalse(remoteTimestamp == nil)
                            XCTAssertTrue(remoteTimestamp >= 1429121686000) // Not a special timestamp; just a sanity check.
                        case let .Local(error):
                            XCTAssertNil(error)
                        }
                    } else {
                        XCTFail("Expected TokenServerError")
                    }
                }
                e.fulfill()
            }
        }
        self.waitForExpectationsWithTimeout(10, handler: nil)
    }
}
