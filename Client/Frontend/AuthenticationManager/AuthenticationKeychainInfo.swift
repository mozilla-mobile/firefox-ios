/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import SwiftKeychainWrapper

public let KeychainKeyAuthenticationInfo = "authenticationInfo"

// MARK: - Helper methods for accessing Authentication information from the Keychain
extension KeychainWrapper {
    class func authenticationInfo() -> AuthenticationKeychainInfo? {
        return KeychainWrapper.objectForKey(KeychainKeyAuthenticationInfo) as? AuthenticationKeychainInfo
    }

    class func setAuthenticationInfo(info: AuthenticationKeychainInfo?) {
        if let info = info {
            KeychainWrapper.setObject(info, forKey: KeychainKeyAuthenticationInfo)
        } else {
            KeychainWrapper.removeObjectForKey(KeychainKeyAuthenticationInfo)
        }
    }
}

class AuthenticationKeychainInfo: NSObject, NSCoding {
    private(set) var lastPasscodeValidationTimestamp: Timestamp?
    private(set) var passcode: String?
    private(set) var requiredPasscodeInterval: PasscodeInterval?

    init(passcode: String) {
        self.passcode = passcode
        self.requiredPasscodeInterval = .Immediately
    }

    func encodeWithCoder(aCoder: NSCoder) {
        if let lastPasscodeValidationTimestamp = lastPasscodeValidationTimestamp {
            let timestampNumber = NSNumber(unsignedLongLong: lastPasscodeValidationTimestamp)
            aCoder.encodeObject(timestampNumber, forKey: "lastPasscodeValidationTimestamp")
        }

        aCoder.encodeObject(passcode, forKey: "passcode")
        aCoder.encodeObject(requiredPasscodeInterval?.rawValue, forKey: "requiredPasscodeInterval")
    }

    required init?(coder aDecoder: NSCoder) {
        self.lastPasscodeValidationTimestamp = (aDecoder.decodeObjectForKey("lastPasscodeValidationTimestamp") as? NSNumber)?.unsignedLongLongValue
        self.passcode = aDecoder.decodeObjectForKey("passcode") as? String
        if let interval = aDecoder.decodeObjectForKey("requiredPasscodeInterval") as? NSNumber {
            self.requiredPasscodeInterval = PasscodeInterval(rawValue: interval.integerValue)
        }
    }
}

// MARK: - API
extension AuthenticationKeychainInfo {
    func updatePasscode(passcode: String) {
        self.passcode = passcode
        self.lastPasscodeValidationTimestamp = nil
    }

    func updateRequiredPasscodeInterval(interval: PasscodeInterval) {
        self.requiredPasscodeInterval = interval
        self.lastPasscodeValidationTimestamp = nil
    }

    func recordValidationTime() {
        self.lastPasscodeValidationTimestamp = NSDate.now()
    }
}