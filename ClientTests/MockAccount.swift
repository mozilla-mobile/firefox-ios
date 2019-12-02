/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

@testable import Account
import Foundation
import Shared
import XCTest

class MockAccount: Account.FirefoxAccount {
    
    // Mock variable for action needed
    var mockActionNeeded: FxAActionNeeded?
    
    // Making the action .none by default for action needed
    // It is mainly for mocking purposes that we override 
    override open var actionNeeded: FxAActionNeeded {
        return mockActionNeeded ?? .none
    }
    
    // Creates a basic mock firefox account for testing purpose
    static func createMockFireFoxAccount() -> MockAccount {
        let prefs = NSUserDefaultsPrefs(prefix: "profile")
        let account = MockAccount(
            configuration: FirefoxAccountConfigurationLabel.production.toConfiguration(prefs: prefs),
                email: "email",
                uid: "uid",
                deviceRegistration: FxADeviceRegistration(id: "bogus-device", version: 0, lastRegistered: Date.now()),
                declinedEngines: nil,
                stateKeyLabel: Bytes.generateGUID(),
                state: SeparatedState(),
                deviceName: "my iphone")

        account.mockActionNeeded = .needsVerification
        
        return account
    }
}
