/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Deferred
import FxA
import Result
import UIKit
import XCTest

class FxAClient10Tests: XCTestCase {
    func testLoginSuccess() {
        let e = self.expectationWithDescription("")

        let email : NSData = "testtestoo@mockmyid.com".utf8EncodedData!
        let password : NSData = email
        let quickStretchedPW : NSData = FxAClient10.quickStretchPW(email, password: password)

        let client = FxAClient10()
        let result = client.login(email, quickStretchedPW: quickStretchedPW, getKeys: true)
        result.upon { result in
            if let response = result.successValue {
                XCTAssertNotNil(response.uid)
                XCTAssertEqual(response.verified, true)
                XCTAssertNotNil(response.sessionToken)
                XCTAssertNotNil(response.keyFetchToken)
            } else {
                let error = result.failureValue as NSError
                XCTAssertNil(error)
            }
            e.fulfill()
        }
        self.waitForExpectationsWithTimeout(10, handler: nil)
    }

    func testLoginFailure() {
        let e = self.expectationWithDescription("")

        let email : NSData = "testtestoo@mockmyid.com".utf8EncodedData!
        let password : NSData = "INCORRECT PASSWORD".utf8EncodedData!
        let quickStretchedPW : NSData = FxAClient10.quickStretchPW(email, password: password)

        let client = FxAClient10()
        let result = client.login(email, quickStretchedPW: quickStretchedPW, getKeys: true)
        result.upon { result in
            if let response = result.successValue {
                XCTFail("Got response: \(response)")
            } else {
                let error = result.failureValue as NSError
                XCTAssertEqual(error.code, 103) // Incorrect password.
            }
            e.fulfill()
        }
        self.waitForExpectationsWithTimeout(10, handler: nil)
    }

    func testKeysSuccess() {
        let e = self.expectationWithDescription("")

        let email : NSData = "testtestoo@mockmyid.com".utf8EncodedData!
        let password : NSData = email
        let quickStretchedPW : NSData = FxAClient10.quickStretchPW(email, password: password)

        let client = FxAClient10()
        let login: Deferred<Result<FxALoginResponse>> = client.login(email, quickStretchedPW: quickStretchedPW, getKeys: true)
        let keys: Deferred<Result<FxAKeysResponse>> = login.bind { (result: Result<FxALoginResponse>) in
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
                let error = result.failureValue as NSError
                XCTAssertNil(error)
            }
            e.fulfill()
        }
        self.waitForExpectationsWithTimeout(10, handler: nil)
    }

    func testSignSuccess() {
        let e = self.expectationWithDescription("")

        let email : NSData = "testtestoo@mockmyid.com".utf8EncodedData!
        let password : NSData = email
        let quickStretchedPW : NSData = FxAClient10.quickStretchPW(email, password: password)

        let client = FxAClient10()
        let login: Deferred<Result<FxALoginResponse>> = client.login(email, quickStretchedPW: quickStretchedPW, getKeys: true)
        let sign: Deferred<Result<FxASignResponse>> = login.bind { (result: Result<FxALoginResponse>) in
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
                let error = result.failureValue as NSError
                XCTAssertNil(error)
            }
            e.fulfill()
        }
        self.waitForExpectationsWithTimeout(10, handler: nil)
    }
}
