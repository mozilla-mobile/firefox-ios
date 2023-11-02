// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Shared
import UIKit
import XCTest

@testable import Account

// Testing client state is so delicate that I'm not going to test this.  The test below does two
// requests; we would need a third, and a guarantee of the server state, to test this completely.
// The rule is: if you turn up with a never-before-seen client state; you win.  If you turn up with
// a seen-before client state, you lose.
class TokenServerClientTests: XCTestCase {
    func testTokenFromJSON() {
        let id = "id"
        let key = "key"
        let apiEndpoint = "api_endpoint"
        let uid = Int64(1)
        let hashedFxAUID = "hashed_fxa_uid"
        let durationInSeconds = Int64(Date.getCurrentPeriod())
        let remoteTimestamp = Int64(Date.getCurrentPeriod())
        let jsonDict: [String: Any] = createMockTokenServerTokenDictionary(id: id, key: key, apiEndpoint: apiEndpoint, uid: uid, hashedFxAUID: hashedFxAUID, durationInSeconds: durationInSeconds, remoteTimestamp: remoteTimestamp)
        let tokenServerToken = TokenServerToken.fromJSON(jsonDict)

        XCTAssertNotNil(tokenServerToken)
        XCTAssertEqual(id, tokenServerToken!.id)
        XCTAssertEqual(key, tokenServerToken!.key)
        XCTAssertEqual(apiEndpoint, tokenServerToken!.api_endpoint)
        XCTAssertEqual(UInt64(uid), tokenServerToken!.uid)
        XCTAssertEqual(hashedFxAUID, tokenServerToken!.hashedFxAUID)
        XCTAssertEqual(UInt64(durationInSeconds), tokenServerToken!.durationInSeconds)
        XCTAssertEqual(UInt64(remoteTimestamp), tokenServerToken!.remoteTimestamp)
    }

    func testTokenAsJSON() {
        let id = "id"
        let key = "key"
        let apiEndpoint = "api_endpoint"
        let uid = Int64(1)
        let hashedFxAUID = "hashed_fxa_uid"
        let durationInSeconds = Int64(Date.getCurrentPeriod())
        let remoteTimestamp = Int64(Date.getCurrentPeriod())

        let tokenServerToken = TokenServerToken(id: id, key: key, api_endpoint: apiEndpoint, uid: UInt64(uid), hashedFxAUID: hashedFxAUID, durationInSeconds: UInt64(durationInSeconds), remoteTimestamp: UInt64(remoteTimestamp))

        let jsonDict = tokenServerToken.asJSON()
        let expectedJsonDict = createMockTokenServerTokenDictionary(id: id, key: key, apiEndpoint: apiEndpoint, uid: uid, hashedFxAUID: hashedFxAUID, durationInSeconds: durationInSeconds, remoteTimestamp: remoteTimestamp)
        XCTAssertTrue(NSDictionary(dictionary: jsonDict).isEqual(to: expectedJsonDict))
    }

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

    // MARK: Helpers
    private func createMockTokenServerTokenDictionary(id: String, key: String, apiEndpoint: String, uid: Int64, hashedFxAUID: String, durationInSeconds: Int64, remoteTimestamp: Int64) -> [String: Any] {
        ["id": id, "key": key, "api_endpoint": apiEndpoint, "uid": uid, "hashed_fxa_uid": hashedFxAUID, "duration": durationInSeconds, "remoteTimestamp": remoteTimestamp]
    }
}
