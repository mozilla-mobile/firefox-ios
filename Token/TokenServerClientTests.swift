/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import XCTest
import FxA
import Client

let TEST_TOKEN_SERVER_ENDPOINT = STAGE_TOKEN_SERVER_ENDPOINT
let TEST_USERNAME = "testuser" // Really, testuser@mockmyid.com.

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

    func testSuccess() {
        let url = TEST_TOKEN_SERVER_ENDPOINT
        let expectation = expectationWithDescription("\(url)")

        let keyPair = RSAKeyPair.generateKeyPairWithModulusSize(512)
        let assertion = MockMyIDTokenFactory.defaultFactory().createAssertionWithKeyPair(keyPair, username: TEST_USERNAME, audience: TokenServerClient.getAudienceForEndpoint(url))

        let client = TokenServerClient(endpoint: url)
        client.tokenRequest(assertion: assertion).onSuccess { (token) in
            expectation.fulfill()
            XCTAssertNotNil(token.id)
            XCTAssertNotNil(token.key)
            XCTAssertNotNil(token.api_endpoint)
            XCTAssertTrue(token.uid >= 0)
            XCTAssertTrue(token.api_endpoint.hasSuffix(String(token.uid)))
            }
            .go { (error) in
                expectation.fulfill()
                println(error)
                XCTFail("should have succeeded");
        }

        waitForExpectationsWithTimeout(10) { (error) in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testFailure() {
        let url = TEST_TOKEN_SERVER_ENDPOINT
        let expectation = expectationWithDescription("\(url)")

        let client = TokenServerClient(endpoint: url)
        client.tokenRequest(assertion: "").onSuccess { (token) in
            expectation.fulfill()
            XCTFail("should have failed");
            }
            .go { (error) in
                expectation.fulfill()
                let t = error.userInfo!["code"]! as Int
                XCTAssertEqual(t, 401)
        }

        waitForExpectationsWithTimeout(10) { (error) in
            XCTAssertNil(error, "\(error)")
        }
    }

//    let TEST_CLIENT_STATE = "1";
//    let TEST_USERNAME_FOR_CLIENT_STATE = "test3";
//
//    // Testing client state so delicate that I'm not going to test this.  The test below does two requests; we would need a third, and a guarantee of the server state, to test this completely.
//    // The rule is: if you turn up with a never-before-seen client state; you win.  If you turn up with a seen-before client state, you lose.
//    func testClientStateMatters() {
//        let url = STAGE_TOKEN_SERVER_ENDPOINT
//        let expectation1 = expectationWithDescription("\(url)")
//        let expectation2 = expectationWithDescription("\(url)")
//
//        let keyPair = RSAKeyPair.generateKeyPairWithModulusSize(512)
//        let assertion = MockMyIDTokenFactory.defaultFactory().createAssertionWithKeyPair(keyPair, username: TEST_USERNAME_FOR_CLIENT_STATE, audience: TokenServerClient.getAudienceForEndpoint(url))
//
//        var token1 : TokenServerToken!
//        var token2 : TokenServerToken!
//
//        let client = TokenServerClient(endpoint: url)
//        client.tokenRequest(assertion: assertion).onSuccess { (token) in
//            expectation1.fulfill()
//            token1 = token
//            }
//            .go { (error) in
//                expectation1.fulfill()
//                println(error.userInfo!["code"]);
//                XCTFail("should have succeeded");
//        }
//
//        client.tokenRequest(assertion: assertion).onSuccess { (token) in
//            expectation2.fulfill()
//            token2 = token
//            }
//            .go { (error) in
//                expectation2.fulfill()
//                println(error.userInfo!["code"]);
//                XCTFail("should have succeeded");
//        }
//
//        waitForExpectationsWithTimeout(10) { (error) in
//            XCTAssertNil(error, "\(error)")
//        }
//
//        XCTAssertNotEqual(token1.uid, token2.uid)
//    }
}
