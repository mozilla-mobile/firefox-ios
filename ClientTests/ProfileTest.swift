/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

@testable import Client
@testable import Account
import Foundation
import Shared
import Storage
import SwiftKeychainWrapper

import XCTest

/*
 * A base test type for tests that need a profile.
 */

class ProfileTest: XCTestCase {
    
    var profile: MockProfile?
    var account: MockAccount?
    
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        
        // Setup mock profile and account
        account = MockAccount.createMockFireFoxAccount()
        profile = MockProfile(databasePrefix: "profile-test")
    }
    
   func withTestProfile(_ callback: (_ profile: Client.Profile) -> Void) {
        guard let mockProfile = profile else {
            return
        }
        mockProfile._reopen()
        callback(mockProfile)
        mockProfile._shutdown()
    }

    func testNewProfileClearsExistingAuthenticationInfo() {
        let authInfo = AuthenticationKeychainInfo(passcode: "1234")
        KeychainWrapper.sharedAppContainerKeychain.setAuthenticationInfo(authInfo)
        XCTAssertNotNil(KeychainWrapper.sharedAppContainerKeychain.authenticationInfo())
        let _ = BrowserProfile(localName: "my_profile", clear: true)
        XCTAssertNil(KeychainWrapper.sharedAppContainerKeychain.authenticationInfo())
    }
    
    func testNeedsVerification() {
        if profile == nil || account == nil {
            XCTAssert(false)
        }
        
        // Setting up the account and profile for needs verification state
        account!.mockActionNeeded = .needsVerification
        profile!.account = account
        
        // Should return true as we are setting up the account to be in needs verification state
        XCTAssert(profile!.accountNeedsUserAction)
    
    }
    
    func testNeedsVerificationForPassword() {
        if profile == nil || account == nil {
            XCTAssert(false)
        }
    
        // Setting up the account and profile for needs verification state
        account!.mockActionNeeded = .needsPassword
        profile!.account = account
        
        // Should return true as we are setting up the account to be in needs password state
        XCTAssert(profile!.accountNeedsUserAction)
    }
}
