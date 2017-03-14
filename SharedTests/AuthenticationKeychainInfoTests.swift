/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import XCTest
import SwiftKeychainWrapper

class AuthenticationKeychainInfoTests: XCTestCase {

    func testEncodingAndDecoding() {
        let passcode = "1234"
        let authInfo = AuthenticationKeychainInfo(passcode: passcode)
        authInfo.updateRequiredPasscodeInterval(.fiveMinutes)
        authInfo.recordValidation()
        authInfo.recordFailedAttempt() // failed attempt should be 1
        authInfo.lockOutUser() //lock out a user so a lockoutInterval is set.
        authInfo.useTouchID = true

        let savedInterval = authInfo.lockOutInterval
        let savedValidation = authInfo.lastPasscodeValidationInterval

        KeychainWrapper.sharedAppContainerKeychain.setAuthenticationInfo(authInfo) //Save to disk
        let decodedAuthInfo = KeychainWrapper.sharedAppContainerKeychain.authenticationInfo()! //Fetch from disk

        XCTAssertEqual(savedInterval, decodedAuthInfo.lockOutInterval)
        XCTAssertEqual(passcode, decodedAuthInfo.passcode)
        XCTAssertEqual(1, decodedAuthInfo.failedAttempts, "We performed a recordFailedAttempt. This should be 1.")
        XCTAssertTrue(decodedAuthInfo.useTouchID)
        XCTAssertEqual(savedValidation, decodedAuthInfo.lastPasscodeValidationInterval)
        XCTAssertEqual(PasscodeInterval.fiveMinutes, decodedAuthInfo.requiredPasscodeInterval)
    }

    func testNilIntervalsArentZero() {
        let passcode = "1234"
        let authInfo = AuthenticationKeychainInfo(passcode: passcode)

        KeychainWrapper.sharedAppContainerKeychain.setAuthenticationInfo(authInfo) //Save to disk
        let decodedAuthInfo = KeychainWrapper.sharedAppContainerKeychain.authenticationInfo()! //Fetch from disk

        XCTAssertNil(decodedAuthInfo.lockOutInterval, "The lockoutInterval was never used. It should be nil")
    }

}
