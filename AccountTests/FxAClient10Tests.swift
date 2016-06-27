/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

@testable import Account
import FxA
import Shared
import UIKit
import Deferred

import XCTest

class FxAClient10Tests: LiveAccountTest {
    func testUnwrapKey() {
        let stretchedPW = "e4e8889bd8bd61ad6de6b95c059d56e7b50dacdaf62bd84644af7e2add84345d".hexDecodedData
        let unwrapKey = FxAClient10.computeUnwrapKey(stretchedPW)
        XCTAssertEqual(unwrapKey.hexEncodedString, "de6a2648b78284fcb9ffa81ba95803309cfba7af583c01a8a1a63e567234dd28")
    }

    func testClientState() {
        let kB = "fd5c747806c07ce0b9d69dcfea144663e630b65ec4963596a22f24910d7dd15d".hexDecodedData
        let clientState = FxAClient10.computeClientState(kB)!
        XCTAssertEqual(clientState, "6ae94683571c7a7c54dab4700aa3995f")
    }

    func testErrorOutput() {
        // Make sure we don't hide error details.
        let error = NSError(domain: "test", code: 123, userInfo: nil)

        let localError = FxAClientError.Local(error)
        XCTAssertEqual(
            localError.description,
            "<FxAClientError.Local Error Domain=test Code=123 \"The operation couldn’t be completed. (test error 123.)\">")
        XCTAssertEqual(
            "\(localError)",
            "<FxAClientError.Local Error Domain=test Code=123 \"The operation couldn’t be completed. (test error 123.)\">")

        let remoteError = FxAClientError.Remote(RemoteError(code: 401, errno: 104,
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
            let e = self.expectation(withDescription: "")

            let client = FxAClient10()
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
        self.waitForExpectations(withTimeout: 10, handler: nil)
    }

    func testLoginFailure() {
        withVerifiedAccount { emailUTF8, _ in
            let e = self.expectation(withDescription: "")

            let badPassword = FxAClient10.quickStretchPW(emailUTF8, password: "BAD PASSWORD".utf8EncodedData!)

            let client = FxAClient10()
            let result = client.login(emailUTF8, quickStretchedPW: badPassword, getKeys: true)
            result.upon { result in
                if let response = result.successValue {
                    XCTFail("Got response: \(response)")
                } else {
                    if let error = result.failureValue as? FxAClientError {
                        switch error {
                        case let .Remote(remoteError):
                            XCTAssertEqual(remoteError.code, Int32(400)) // Bad auth.
                            XCTAssertEqual(remoteError.errno, Int32(103)) // Incorrect password.
                        case let .Local(error):
                            XCTAssertEqual(error.description, "")
                        }
                    } else {
                        XCTAssertEqual(result.failureValue!.description, "")
                    }
                }
                e.fulfill()
            }
        }
        self.waitForExpectations(withTimeout: 10, handler: nil)
    }

    func testKeysSuccess() {
        withVerifiedAccount { emailUTF8, quickStretchedPW in
            let e = self.expectation(withDescription: "")

            let client = FxAClient10()
            let login: Deferred<Maybe<FxALoginResponse>> = client.login(emailUTF8, quickStretchedPW: quickStretchedPW, getKeys: true)
            let keys: Deferred<Maybe<FxAKeysResponse>> = login.bind { (result: Maybe<FxALoginResponse>) in
                switch result {
                case let .Failure(error):
                    return Deferred(value: .Failure(error))
                case let .Success(loginResponse):
                    return client.keys(loginResponse.value.keyFetchToken)
                }
            }
            keys.upon { result in
                if let response = result.successValue {
                    XCTAssertEqual(32, response.kA.length)
                    XCTAssertEqual(32, response.wrapkB.length)
                } else {
                    XCTAssertEqual(result.failureValue!.description, "")
                }
                e.fulfill()
            }
        }
        self.waitForExpectations(withTimeout: 10, handler: nil)
    }

    func testSignSuccess() {
        withVerifiedAccount { emailUTF8, quickStretchedPW in
            let e = self.expectation(withDescription: "")

            let client = FxAClient10()
            let login: Deferred<Maybe<FxALoginResponse>> = client.login(emailUTF8, quickStretchedPW: quickStretchedPW, getKeys: true)
            let sign: Deferred<Maybe<FxASignResponse>> = login.bind { (result: Maybe<FxALoginResponse>) in
                switch result {
                case let .Failure(error):
                    return Deferred(value: .Failure(error))
                case let .Success(loginResponse):
                    let keyPair = RSAKeyPair.generateKeyPairWithModulusSize(1024)
                    return client.sign(loginResponse.value.sessionToken, publicKey: keyPair.publicKey)
                }
            }
            sign.upon { result in
                if let response = result.successValue {
                    XCTAssertNotNil(response.certificate)
                    // A simple test that we got a reasonable certificate back.
                    XCTAssertEqual(3, response.certificate.componentsSeparatedByString(".").count)
                } else {
                    XCTAssertEqual(result.failureValue!.description, "")
                }
                e.fulfill()
            }
        }
        self.waitForExpectations(withTimeout: 10, handler: nil)
    }
}
