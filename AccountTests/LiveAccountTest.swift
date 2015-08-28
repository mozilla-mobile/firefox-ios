/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import FxA
import Account
import XCTest

/*
 * A base test type for tests that need a live Firefox Account.
 */
public class LiveAccountTest: XCTestCase {
    lazy var signedInUser: JSON? = {
        if let path = NSBundle(forClass: self.dynamicType).pathForResource("signedInUser.json", ofType: nil) {
            if let contents = try? String(contentsOfFile: path, encoding: NSUTF8StringEncoding) {
                let json = JSON.parse(contents)
                if json.isError {
                    return nil
                }
                if let email = json["email"].asString {
                    return json
                }  else {
                    // This is the standard case: signedInUser.json is {}.
                    return nil
                }
            }
        }
        XCTFail("Expected to read signedInUser.json!")
        return nil
    }()

    // It's not easy to have an optional resource, so we always include signedInUser.json in the test bundle.
    // If signedInUser.json contains an email address, we use that email address.
    // Since there's no way to get the corresponding password (from any client!), we assume that any
    // test account has password identical to its email address.
    private func withExistingAccount(mustBeVerified: Bool, completion: (NSData, NSData) -> Void) {
        // If we don't create at least one expectation, waitForExpectations fails.
        // So we unconditionally create one, even though the callback may not execute.
        self.expectationWithDescription("withExistingAccount").fulfill()
        if let json = self.signedInUser {
            if mustBeVerified {
                XCTAssertTrue(json["verified"].asBool ?? false)
            }
            let email = json["email"].asString!
            let emailUTF8 = email.utf8EncodedData!
            let password = email.utf8EncodedData!
            let stretchedPW = FxAClient10.quickStretchPW(emailUTF8, password: password)
            completion(emailUTF8, stretchedPW)
        } else {
            // This is the standard case: signedInUser.json is {}.
            NSLog("Skipping test because signedInUser.json does not include email address.")
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
            let login: Deferred<Maybe<FxALoginResponse>> = client.login(emailUTF8, quickStretchedPW: quickStretchedPW, getKeys: true)
            let sign: Deferred<Maybe<FxASignResponse>> = login.bind { (result: Maybe<FxALoginResponse>) in
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
                    XCTAssertEqual(result.failureValue!.description, "")
                    expectation.fulfill()
                }
            }
        }
    }

    public enum AccountError: MaybeErrorType {
        case BadParameters
        case NoSignedInUser
        case UnverifiedSignedInUser

        public var description: String {
            switch self {
            case BadParameters: return "Bad account parameters (email, password, or a derivative thereof)."
            case NoSignedInUser: return "No signedInUser.json (missing, no email, etc)."
            case UnverifiedSignedInUser: return "signedInUser.json describes an unverified account."
            }
        }
    }

    // Internal helper.
    func account(email: String, password: String, configuration: FirefoxAccountConfiguration) -> Deferred<Maybe<FirefoxAccount>> {
        let client = FxAClient10(endpoint: configuration.authEndpointURL)
        if let emailUTF8 = email.utf8EncodedData {
            if let passwordUTF8 = email.utf8EncodedData {
                let quickStretchedPW = FxAClient10.quickStretchPW(emailUTF8, password: passwordUTF8)
                let login = client.login(emailUTF8, quickStretchedPW: quickStretchedPW, getKeys: true)
                return login.bind { result in
                    if let response = result.successValue {
                        let unwrapkB = FxAClient10.computeUnwrapKey(quickStretchedPW)
                        return Deferred(value: Maybe(success: FirefoxAccount.fromConfigurationAndLoginResponse(configuration, response: response, unwrapkB: unwrapkB)))
                    } else {
                        return Deferred(value: Maybe(failure: result.failureValue!))
                    }
                }
            }
        }
        return Deferred(value: Maybe(failure: AccountError.BadParameters))
    }

    // Override this to configure test account.
    public func account() -> Deferred<Maybe<FirefoxAccount>> {
        if self.signedInUser == nil {
            return Deferred(value: Maybe(failure: AccountError.NoSignedInUser))
        }
        if !(self.signedInUser?["verified"].asBool ?? false) {
            return Deferred(value: Maybe(failure: AccountError.UnverifiedSignedInUser))
        }
        return self.account("testtesto@mockmyid.com", password: "testtesto@mockmyid.com",
            configuration: ProductionFirefoxAccountConfiguration())
    }

    func getTestAccount() -> Deferred<Maybe<FirefoxAccount>> {
        // TODO: Use signedInUser.json here.  It's hard to include the same resource file in two Xcode targets.
        return self.account("testtesto@mockmyid.com", password: "testtesto@mockmyid.com",
            configuration: ProductionFirefoxAccountConfiguration())
    }

    public func getAuthState(now: Timestamp) -> Deferred<Maybe<SyncAuthState>> {
        let account = self.getTestAccount()
        print("Got test account.")
        return account.map { result in
            print("Result was successful? \(result.isSuccess)")
            if let account = result.successValue {
                return Maybe(success: account.syncAuthState)
            }
            return Maybe(failure: result.failureValue!)
        }
    }

    public func syncAuthState(now: Timestamp) -> Deferred<Maybe<(token: TokenServerToken, forKey: NSData)>> {
        return getAuthState(now).bind { result in
            if let authState = result.successValue {
                return authState.token(now, canBeExpired: false)
            }
            return Deferred(value: Maybe(failure: result.failureValue!))
        }
    }
}
