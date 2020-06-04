/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

@testable import Account
import FxA
import Shared
import UIKit

import XCTest

// Production Server URLs
// From https://accounts.firefox.com/.well-known/fxa-client-configuration
private let ProductionAuthEndpointURL = URL(string: "https://api.accounts.firefox.com/v1")!
private let ProductionOAuthEndpointURL = URL(string: "https://oauth.accounts.firefox.com/v1")!
private let ProductionProfileEndpointURL = URL(string: "https://profile.accounts.firefox.com/v1")!

// Stage Server URLs
// From https://accounts.stage.mozaws.net/.well-known/fxa-client-configuration
private let StageAuthEndpointURL = URL(string: "https://api-accounts.stage.mozaws.net/v1")!
private let StageOAuthEndpointURL = URL(string: "https://oauth.stage.mozaws.net/v1")!
private let StageProfileEndpointURL = URL(string: "https://profile.stage.mozaws.net/v1")!

class FxAClient10Tests: LiveAccountTest {
    func testUnwrapKey() {
        let stretchedPW = "e4e8889bd8bd61ad6de6b95c059d56e7b50dacdaf62bd84644af7e2add84345d".hexDecodedData
        let unwrapKey = FxAClient10.computeUnwrapKey(stretchedPW)
        XCTAssertEqual(unwrapKey.hexEncodedString, "de6a2648b78284fcb9ffa81ba95803309cfba7af583c01a8a1a63e567234dd28")
    }

    func testClientState() {
        let kB = "fd5c747806c07ce0b9d69dcfea144663e630b65ec4963596a22f24910d7dd15d".hexDecodedData
        let clientState = FxAClient10.computeClientState(kB)
        XCTAssertEqual(clientState, "6ae94683571c7a7c54dab4700aa3995f")
    }

    func testDeriveKSync() {
        let kB = "fd5c747806c07ce0b9d69dcfea144663e630b65ec4963596a22f24910d7dd15d".hexDecodedData
        let kSyncHex = FxAClient10.deriveKSync(kB).hexEncodedString
        XCTAssertEqual(kSyncHex, "ad501a50561be52b008878b2e0d8a73357778a712255f7722f497b5d4df14b05dc06afb836e1521e882f521eb34691d172337accdbf6e2a5b968b05a7bbb9885")
    }

    func testErrorOutput() {
        // Make sure we don't hide error details.
        let error = NSError(domain: "test", code: 123, userInfo: nil)

        let localError = FxAClientError.local(error)
        XCTAssertEqual(
            localError.description,
            "<FxAClientError.Local Error Domain=test Code=123 \"The operation couldn’t be completed. (test error 123.)\">")
        XCTAssertEqual(
            "\(localError)",
            "<FxAClientError.Local Error Domain=test Code=123 \"The operation couldn’t be completed. (test error 123.)\">")

        let remoteError = FxAClientError.remote(RemoteError(code: 401, errno: 104,
            error: "error", message: "message", info: "info"))
        XCTAssertEqual(
            remoteError.description,
            "<FxAClientError.Remote 401/104: error (message)>")
        XCTAssertEqual(
            "\(remoteError)",
            "<FxAClientError.Remote 401/104: error (message)>")
    }

    func testLoginSuccess() {
        withVerifiedAccount { emailUTF8, quickStretchedPW in
            let e = self.expectation(description: "")

            let client = FxAClient10(authEndpoint: ProductionAuthEndpointURL, oauthEndpoint: ProductionOAuthEndpointURL, profileEndpoint: ProductionProfileEndpointURL)
            let result = client.login(emailUTF8, quickStretchedPW: quickStretchedPW, getKeys: true)
            result.upon { result in
                if let response = result.successValue {
                    XCTAssertNotNil(response.uid)
                    XCTAssertEqual(response.verified, true)
                    XCTAssertNotNil(response.sessionToken)
                    XCTAssertNotNil(response.keyFetchToken)
                } else {
                    XCTAssertEqual(result.failureValue!.description, "")
                }
                e.fulfill()
            }
        }
        self.waitForExpectations(timeout: 10, handler: nil)
    }

    func testLoginFailure() {
        withVerifiedAccount { emailUTF8, _ in
            let e = self.expectation(description: "")

            let badPassword = FxAClient10.quickStretchPW(emailUTF8, password: "BAD PASSWORD".utf8EncodedData)

            let client = FxAClient10(authEndpoint: ProductionAuthEndpointURL, oauthEndpoint: ProductionOAuthEndpointURL, profileEndpoint: ProductionProfileEndpointURL)
            let result = client.login(emailUTF8, quickStretchedPW: badPassword, getKeys: true)
            result.upon { result in
                if let response = result.successValue {
                    XCTFail("Got response: \(response)")
                } else {
                    if let error = result.failureValue as? FxAClientError {
                        switch error {
                        case let .remote(remoteError):
                            XCTAssertEqual(remoteError.code, Int32(400)) // Bad auth.
                            XCTAssertEqual(remoteError.errno, Int32(103)) // Incorrect password.
                        case let .local(error):
                            XCTAssertEqual(error.description, "")
                        }
                    } else {
                        XCTAssertEqual(result.failureValue!.description, "")
                    }
                }
                e.fulfill()
            }
        }
        self.waitForExpectations(timeout: 10, handler: nil)
    }

    func testKeysSuccess() {
        withVerifiedAccount { emailUTF8, quickStretchedPW in
            let e = self.expectation(description: "")

            let client = FxAClient10(authEndpoint: ProductionAuthEndpointURL, oauthEndpoint: ProductionOAuthEndpointURL, profileEndpoint: ProductionProfileEndpointURL)
            let login: Deferred<Maybe<FxALoginResponse>> = client.login(emailUTF8, quickStretchedPW: quickStretchedPW, getKeys: true)
            let keys: Deferred<Maybe<FxAKeysResponse>> = login.bind { (result: Maybe<FxALoginResponse>) in
                switch result {
                case let .failure(error):
                    return Deferred(value: .failure(error))
                case let .success(loginResponse):
                    return client.keys(loginResponse.keyFetchToken)
                }
            }
            keys.upon { result in
                if let response = result.successValue {
                    XCTAssertEqual(32, response.kA.count)
                    XCTAssertEqual(32, response.wrapkB.count)
                } else {
                    XCTAssertEqual(result.failureValue!.description, "")
                }
                e.fulfill()
            }
        }
        self.waitForExpectations(timeout: 10, handler: nil)
    }

    func testSignSuccess() {
        withVerifiedAccount { emailUTF8, quickStretchedPW in
            let e = self.expectation(description: "")

            let client = FxAClient10(authEndpoint: ProductionAuthEndpointURL, oauthEndpoint: ProductionOAuthEndpointURL, profileEndpoint: ProductionProfileEndpointURL)
            let login: Deferred<Maybe<FxALoginResponse>> = client.login(emailUTF8, quickStretchedPW: quickStretchedPW, getKeys: true)
            let sign: Deferred<Maybe<FxASignResponse>> = login.bind { (result: Maybe<FxALoginResponse>) in
                switch result {
                case let .failure(error):
                    return Deferred(value: .failure(error))
                case let .success(loginResponse):
                    let keyPair = RSAKeyPair.generate(withModulusSize: 1024)!
                    return client.sign(loginResponse.sessionToken, publicKey: keyPair.publicKey)
                }
            }
            sign.upon { result in
                if let response = result.successValue {
                    XCTAssertNotNil(response.certificate)
                    // A simple test that we got a reasonable certificate back.
                    XCTAssertEqual(3, response.certificate.components(separatedBy: ".").count)
                } else {
                    XCTAssertEqual(result.failureValue!.description, "")
                }
                e.fulfill()
            }
        }
        self.waitForExpectations(timeout: 10, handler: nil)
    }

    func testProfileSuccess() {
        withVerifiedAccountNoExpectations { emailUTF8, quickStretchedPW in
            let client = FxAClient10(authEndpoint: StageAuthEndpointURL, oauthEndpoint: StageOAuthEndpointURL, profileEndpoint: StageProfileEndpointURL)
            let response = (client.login(emailUTF8, quickStretchedPW: quickStretchedPW, getKeys: true) >>== { login in
                return client.getProfile(withSessionToken: login.sessionToken as NSData)
            }).value.successValue
            XCTAssertNotNil(response?.uid)
        }
    }

    func testScopedKeyDataSuccess() {
        withVerifiedAccountNoExpectations { emailUTF8, quickStretchedPW in
            let client = FxAClient10(authEndpoint: StageAuthEndpointURL, oauthEndpoint: StageOAuthEndpointURL, profileEndpoint: StageProfileEndpointURL)
            let response = (client.login(emailUTF8, quickStretchedPW: quickStretchedPW, getKeys: true) >>== { login in
                    return client.scopedKeyData(login.sessionToken as NSData, scope: "profile")
                }).value.successValue
            XCTAssert(response!.count > 0)
        }
    }
}
