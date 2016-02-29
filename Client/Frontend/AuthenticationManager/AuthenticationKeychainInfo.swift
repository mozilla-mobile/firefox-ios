/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import SwiftKeychainWrapper

public let KeychainKeyAuthenticationInfo = "authenticationInfo"
public let AllowedPasscodeFailedAttempts = 3

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
    private(set) var lockOutTimestamp: Timestamp?
    private(set) var failedAttempts: Int

    // Timeout period before user can retry entering passcodes
    var lockTimeInterval = 15 * OneMinuteInMilliseconds

    init(passcode: String) {
        self.passcode = passcode
        self.requiredPasscodeInterval = .Immediately
        self.failedAttempts = 0
    }

    func encodeWithCoder(aCoder: NSCoder) {
        if let lastPasscodeValidationTimestamp = lastPasscodeValidationTimestamp {
            let timestampNumber = NSNumber(unsignedLongLong: lastPasscodeValidationTimestamp)
            aCoder.encodeObject(timestampNumber, forKey: "lastPasscodeValidationTimestamp")
        }

        if let lockOutTimestamp = lockOutTimestamp where isLocked() {
            let timestampNumber = NSNumber(unsignedLongLong: lockOutTimestamp)
            aCoder.encodeObject(timestampNumber, forKey: "lockOutTimestamp")
        }

        aCoder.encodeObject(passcode, forKey: "passcode")
        aCoder.encodeObject(requiredPasscodeInterval?.rawValue, forKey: "requiredPasscodeInterval")
        aCoder.encodeInteger(failedAttempts, forKey: "failedAttempts")
    }

    required init?(coder aDecoder: NSCoder) {
        self.lastPasscodeValidationTimestamp = (aDecoder.decodeObjectForKey("lastPasscodeValidationTimestamp") as? NSNumber)?.unsignedLongLongValue
        self.lockOutTimestamp = (aDecoder.decodeObjectForKey("lockOutTimestamp") as? NSNumber)?.unsignedLongLongValue
        self.passcode = aDecoder.decodeObjectForKey("passcode") as? String
        self.failedAttempts = aDecoder.decodeIntegerForKey("failedAttempts")
        if let interval = aDecoder.decodeObjectForKey("requiredPasscodeInterval") as? NSNumber {
            self.requiredPasscodeInterval = PasscodeInterval(rawValue: interval.integerValue)
        }
    }
}

// MARK: - API
extension AuthenticationKeychainInfo {
    private func resetLockoutState() {
        self.failedAttempts = 0
        self.lockOutTimestamp = nil
    }

    func updatePasscode(passcode: String) {
        self.passcode = passcode
        self.lastPasscodeValidationTimestamp = nil
    }

    func updateRequiredPasscodeInterval(interval: PasscodeInterval) {
        self.requiredPasscodeInterval = interval
        self.lastPasscodeValidationTimestamp = nil
    }

    func recordValidation() {
        // Save the timestamp to remember the last time we successfully 
        // validated and clear out the failed attempts counter.
        self.lastPasscodeValidationTimestamp = NSDate.now()
        resetLockoutState()
    }

    func lockOutUser() {
        self.lockOutTimestamp = NSProcessInfo().systemUptimeTimestamp()
    }

    func recordFailedAttempt() {
        self.failedAttempts += 1
    }

    func isLocked() -> Bool {
        if NSProcessInfo().systemUptimeTimestamp() < self.lockOutTimestamp {
            // Unlock and require passcode input
            resetLockoutState()
            return false
        }
        return (NSProcessInfo().systemUptimeTimestamp() - (self.lockOutTimestamp ?? 0)) < lockTimeInterval
    }
}

extension NSProcessInfo {
    public func systemUptimeTimestamp() -> Timestamp {
        return Timestamp(NSProcessInfo().systemUptime * NSTimeInterval(OneSecondInMilliseconds))
    }
}