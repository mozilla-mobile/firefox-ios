// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Client

final class CertificateDelegateTests: XCTestCase {
    func testDelegate_withNoServerTrust_callsCompletionWithNilAndCancels() async {
        let expectation = expectation(description: "completion called with nil")
        let delegate = CertificateDelegate { certificates in
            XCTAssertNil(certificates)
            expectation.fulfill()
        }

        let challenge = URLAuthenticationChallenge(
            protectionSpace: URLProtectionSpace(
                host: "example.com",
                port: 443,
                protocol: "https",
                realm: nil,
                authenticationMethod: NSURLAuthenticationMethodHTTPBasic
            ),
            proposedCredential: nil,
            previousFailureCount: 0,
            failureResponse: nil,
            error: nil,
            sender: MockChallengeSender()
        )

        let (disposition, credential) = await delegate.urlSession(
            URLSession(configuration: .ephemeral),
            didReceive: challenge
        )

        XCTAssertEqual(disposition, .cancelAuthenticationChallenge)
        XCTAssertNil(credential)
        await fulfillment(of: [expectation], timeout: 1)
    }
}

private final class MockChallengeSender: NSObject, URLAuthenticationChallengeSender {
    func use(_ credential: URLCredential, for challenge: URLAuthenticationChallenge) {}
    func continueWithoutCredential(for challenge: URLAuthenticationChallenge) {}
    func cancel(_ challenge: URLAuthenticationChallenge) {}
}
