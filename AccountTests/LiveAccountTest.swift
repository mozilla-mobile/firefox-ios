/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

@testable import Account
import Foundation
import FxA
import Shared
import SwiftyJSON

import XCTest

// Note: All live account tests have been disabled. Please see https://bugzilla.mozilla.org/show_bug.cgi?id=1332028.

// Production Server URLs
// From https://accounts.firefox.com/.well-known/fxa-client-configuration
private let ProductionAuthEndpointURL = URL(string: "https://api.accounts.firefox.com/v1")!
private let ProductionOAuthEndpointURL = URL(string: "https://oauth.accounts.firefox.com/v1")!
private let ProductionProfileEndpointURL = URL(string: "https://profile.accounts.firefox.com/v1")!

/*
 * A base test type for tests that need a live Firefox Account.
 */
open class LiveAccountTest: XCTestCase {
    lazy var signedInUser: JSON? = {
        if let path = Bundle(for: type(of: self)).path(forResource: "signedInUser.json", ofType: nil) {
            if let contents = try? String(contentsOfFile: path, encoding: .utf8) {
                let json = JSON(parseJSON: contents)
                if json.isError() {
                    return nil
                }
                if let email = json["email"].string {
                    return json
                } else {
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
    fileprivate func withExistingAccount(_ mustBeVerified: Bool, completion: (Data, Data) -> Void) {
        // If we don't create at least one expectation, waitForExpectations fails.
        // So we unconditionally create one, even though the callback may not execute.
        self.expectation(description: "withExistingAccount").fulfill()
        if let json = self.signedInUser {
            if mustBeVerified {
                XCTAssertTrue(json["verified"].bool ?? false)
            }
            let email = json["email"].stringValue
            let password = json["password"].stringValue
            let emailUTF8 = email.utf8EncodedData
            let passwordUT8 = password.utf8EncodedData
            let stretchedPW = FxAClient10.quickStretchPW(emailUTF8, password: passwordUT8)
            completion(emailUTF8, stretchedPW)
        } else {
            // This is the standard case: signedInUser.json is {}.
            NSLog("Skipping test because signedInUser.json does not include email address.")
        }
    }

    func withVerifiedAccount(_ completion: (Data, Data) -> Void) {
        withExistingAccount(true, completion: completion)
    }

    // Helper function that waits for expectations to clear
    func withVerifiedAccountNoExpectations(_ completion: (Data, Data) -> Void) {
        withExistingAccount(true, completion: completion)
        self.waitForExpectations(timeout: 10, handler: nil)
    }

    func withCertificate(_ completion: @escaping (XCTestExpectation, Data, KeyPair, String) -> Void) {
        withVerifiedAccount { emailUTF8, quickStretchedPW in
            let expectation = self.expectation(description: "withCertificate")

            let keyPair = RSAKeyPair.generate(withModulusSize: 1024)!
            let client = FxAClient10(authEndpoint: ProductionAuthEndpointURL, oauthEndpoint: ProductionOAuthEndpointURL, profileEndpoint: ProductionProfileEndpointURL)
            let login: Deferred<Maybe<FxALoginResponse>> = client.login(emailUTF8, quickStretchedPW: quickStretchedPW, getKeys: true)
            let sign: Deferred<Maybe<FxASignResponse>> = login.bind { (result: Maybe<FxALoginResponse>) in
                switch result {
                case let .failure(error):
                    expectation.fulfill()
                    return Deferred(value: .failure(error))
                case let .success(loginResponse):
                    return client.sign(loginResponse.sessionToken, publicKey: keyPair.publicKey)
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
        case badParameters
        case noSignedInUser
        case unverifiedSignedInUser

        public var description: String {
            switch self {
            case .badParameters: return "Bad account parameters (email, password, or a derivative thereof)."
            case .noSignedInUser: return "No signedInUser.json (missing, no email, etc)."
            case .unverifiedSignedInUser: return "signedInUser.json describes an unverified account."
            }
        }
    }

    // Internal helper.
    func account(_ email: String, password: String, deviceName: String, configuration: FirefoxAccountConfiguration) -> Deferred<Maybe<FirefoxAccount>> {
        let client = FxAClient10(configuration: configuration)
        let emailUTF8 = email.utf8EncodedData
        let passwordUTF8 = password.utf8EncodedData
        let quickStretchedPW = FxAClient10.quickStretchPW(emailUTF8, password: passwordUTF8)
        let login = client.login(emailUTF8, quickStretchedPW: quickStretchedPW, getKeys: true)
        return login.bind { result in
            if let response = result.successValue {
                let unwrapkB = FxAClient10.computeUnwrapKey(quickStretchedPW)
                return Deferred(value: Maybe(success: FirefoxAccount.from(configuration, andLoginResponse: response, unwrapkB: unwrapkB, deviceName: deviceName)))
            } else {
                return Deferred(value: Maybe(failure: result.failureValue!))
            }
        }
    }

    func getTestAccount() -> Deferred<Maybe<FirefoxAccount>> {
        // TODO: Use signedInUser.json here.  It's hard to include the same resource file in two Xcode targets.
        let prefs = NSUserDefaultsPrefs(prefix: "profile")
        return self.account("998797987.sync@restmail.net", password: "998797987.sync@restmail.net", deviceName: "My iPhone",
                            configuration: ProductionFirefoxAccountConfiguration(prefs: prefs))
    }

    open func getAuthState(_ now: Timestamp) -> Deferred<Maybe<SyncAuthState>> {
        let account = self.getTestAccount()
        print("Got test account.")
        return account.map { result in
            print("Result was successful? \(result.isSuccess)")
//            if let account = result.successValue {
//                return Maybe(success: account.syncAuthState)
//            }
            return Maybe(failure: result.failureValue!)
        }
    }

    open func syncAuthState(_ now: Timestamp) -> Deferred<Maybe<(token: TokenServerToken, forKey: Data)>> {
        return getAuthState(now).bind { result in
            if let authState = result.successValue {
                return authState.token(now, canBeExpired: false)
            }
            return Deferred(value: Maybe(failure: result.failureValue!))
        }
    }
}
