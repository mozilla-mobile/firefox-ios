// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Security
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

    func testDelegate_withServerTrust_callsCompletionWithCertsAndUsesCredential() async throws {
        let generated = try CertificateTestFactory.makeSelfSigned(commonName: "leaf.test")
        let trust = try CertificateTestFactory.makeTrust(from: [generated.secCertificate])

        let expectation = expectation(description: "completion called with certs")
        let delegate = CertificateDelegate { certificates in
            XCTAssertEqual(certificates?.count, 1)
            XCTAssertEqual(certificates?.first?.subject, generated.certificate.subject)
            expectation.fulfill()
        }

        let challenge = URLAuthenticationChallenge(
            protectionSpace: MockServerTrustProtectionSpace(trust: trust),
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

        XCTAssertEqual(disposition, .useCredential)
        XCTAssertNotNil(credential)
        await fulfillment(of: [expectation], timeout: 1)
    }
}

/// `URLProtectionSpace` doesn't expose an initializer for `serverTrust`, so we subclass it
/// and override the read-only property to hand tests a real trust.
private final class MockServerTrustProtectionSpace: URLProtectionSpace, @unchecked Sendable {
    private let trust: SecTrust

    init(trust: SecTrust) {
        self.trust = trust
        super.init(host: "example.com",
                   port: 443,
                   protocol: "https",
                   realm: nil,
                   authenticationMethod: NSURLAuthenticationMethodServerTrust)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported in tests") }

    override var serverTrust: SecTrust? { trust }
}

private final class MockChallengeSender: NSObject, URLAuthenticationChallengeSender {
    func use(_ credential: URLCredential, for challenge: URLAuthenticationChallenge) {}
    func continueWithoutCredential(for challenge: URLAuthenticationChallenge) {}
    func cancel(_ challenge: URLAuthenticationChallenge) {}
}
