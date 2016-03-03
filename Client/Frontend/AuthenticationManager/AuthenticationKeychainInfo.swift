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
    private(set) var lastPasscodeValidationInterval: NSTimeInterval?
    private(set) var passcode: String?
    private(set) var requiredPasscodeInterval: PasscodeInterval?
    private(set) var lockOutInterval: NSTimeInterval?
    private(set) var failedAttempts: Int

    // Timeout period before user can retry entering passcodes
    var lockTimeInterval: NSTimeInterval = 15 * 60

    init(passcode: String) {
        self.passcode = passcode
        self.requiredPasscodeInterval = .Immediately
        self.failedAttempts = 0
    }

    func encodeWithCoder(aCoder: NSCoder) {
        if let lastPasscodeValidationInterval = lastPasscodeValidationInterval {
            let interval = NSNumber(double: lastPasscodeValidationInterval)
            aCoder.encodeObject(interval, forKey: "lastPasscodeValidationInterval")
        }

        if let lockOutInterval = lockOutInterval where isLocked() {
            let interval = NSNumber(double: lockOutInterval)
            aCoder.encodeObject(interval, forKey: "lockOutInterval")
        }

        aCoder.encodeObject(passcode, forKey: "passcode")
        aCoder.encodeObject(requiredPasscodeInterval?.rawValue, forKey: "requiredPasscodeInterval")
        aCoder.encodeInteger(failedAttempts, forKey: "failedAttempts")
    }

    required init?(coder aDecoder: NSCoder) {
        self.lastPasscodeValidationInterval = (aDecoder.decodeObjectForKey("lastPasscodeValidationInterval") as? NSNumber)?.doubleValue
        self.lockOutInterval = (aDecoder.decodeObjectForKey("lockOutInterval") as? NSNumber)?.doubleValue
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
        self.lockOutInterval = nil
    }

    func updatePasscode(passcode: String) {
        self.passcode = passcode
        self.lastPasscodeValidationInterval = nil
    }

    func updateRequiredPasscodeInterval(interval: PasscodeInterval) {
        self.requiredPasscodeInterval = interval
        self.lastPasscodeValidationInterval = nil
    }

    func recordValidation() {
        // Save the timestamp to remember the last time we successfully 
        // validated and clear out the failed attempts counter.
        self.lastPasscodeValidationInterval = SystemUtils.systemUptime()
        resetLockoutState()
    }

    func lockOutUser() {
        self.lockOutInterval = SystemUtils.systemUptime()
    }

    func recordFailedAttempt() {
        self.failedAttempts += 1
    }

    func isLocked() -> Bool {
        if SystemUtils.systemUptime() < self.lockOutInterval {
            // Unlock and require passcode input
            resetLockoutState()
            return false
        }
        return (SystemUtils.systemUptime() - (self.lockOutInterval ?? 0)) < lockTimeInterval
    }

    func requiresValidation() -> Bool {
        // If there isn't a passcode, don't need validation.
        guard let _ = passcode else {
            return false
        }

        // Need to make sure we've validated in the past. If not, its a definite yes.
        guard let lastValidationInterval = lastPasscodeValidationInterval,
                  requireInterval = requiredPasscodeInterval
        else {
            return true
        }

        // We've authenticated before so lets see how long since. If the uptime is less than the last validation stamp,
        // we probably restarted which means we should require validation.
        return SystemUtils.systemUptime() - lastValidationInterval > Double(requireInterval.rawValue) ||
               SystemUtils.systemUptime() < lastValidationInterval
    }
}