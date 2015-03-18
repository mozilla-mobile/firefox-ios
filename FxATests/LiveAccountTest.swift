/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Shared
import Foundation
import FxA
import XCTest

/*
 * A base test type for tests that need a live Firefox Account.
 */
class LiveAccountTest: XCTestCase {
    // It's not easy to have an optional resource, so we always include signedInUser.json in the test bundle.
    // If signedInUser.json contains an email address, we use that email address.
    // Since there's no way to get the corresponding password (from any client!), we assume that any
    // test account has password identical to its email address.
    private func withExistingAccount(mustBeVerified: Bool, completion: (NSData, NSData) -> Void) {
        // If we don't create at least one expectation, waitForExpectations fails.
        // So we unconditionally create one, even though the callback may not execute.
        self.expectationWithDescription("withExistingAccount").fulfill()

        if let path = NSBundle(forClass: self.dynamicType).pathForResource("signedInUser.json", ofType: nil) {
            if let contents = String(contentsOfFile: path, encoding: NSUTF8StringEncoding, error: nil) {
                let json = JSON.parse(contents)
                XCTAssertFalse(json.isError)
                if let email = json["accountData"]["email"].asString {
                    if mustBeVerified {
                        XCTAssertTrue(json["accountData"]["verified"].asBool!)
                    }
                    let emailUTF8 = email.utf8EncodedData!
                    let password = email.utf8EncodedData!
                    let stretchedPW = FxAClient10.quickStretchPW(emailUTF8, password: password)
                    completion(emailUTF8, stretchedPW)
                    return
                } else {
                    // This is the standard case: signedInUser.json is {}.
                    NSLog("Skipping test because signedInUser.json does not include email address.")
                }
            }
        } else {
            XCTFail("Expected to read signedInUser.json!")
        }
    }

    func withVerifiedAccount(completion: (NSData, NSData) -> Void) {
        withExistingAccount(true, completion: completion)
    }

    func withCertificate(completion: (XCTestExpectation, NSData, KeyPair, String) -> Void) {
        withVerifiedAccount { emailUTF8, quickStretchedPW in
            let expectation = self.expectationWithDescription("withCertificate")

            let keyPair = RSAKeyPair.generateKeyPairWithModulusSize(1024)
            let client = FxAClient10()
            let login: Deferred<Result<FxALoginResponse>> = client.login(emailUTF8, quickStretchedPW: quickStretchedPW, getKeys: true)
            let sign: Deferred<Result<FxASignResponse>> = login.bind { (result: Result<FxALoginResponse>) in
                switch result {
                case let .Failure(error):
                    expectation.fulfill()
                    return Deferred(value: .Failure(error))
                case let .Success(loginResponse):
                    return client.sign(loginResponse.value.sessionToken, publicKey: keyPair.publicKey)
                }
            }
            sign.upon { result in
                if let response = result.successValue {
                    XCTAssertNotNil(response.certificate)
                    completion(expectation, emailUTF8, keyPair, response.certificate)
                } else {
                    let error = result.failureValue as NSError
                    XCTAssertNil(error)
                    expectation.fulfill()
                }
            }
        }
    }
}
