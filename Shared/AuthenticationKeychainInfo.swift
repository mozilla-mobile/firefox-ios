/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import SwiftKeychainWrapper

public let KeychainKeyAuthenticationInfo = "authenticationInfo"
public let AllowedPasscodeFailedAttempts = 3

// Passcode intervals with rawValue in seconds.
public enum PasscodeInterval: Int {
    case immediately    = 2
    case oneMinute      = 60
    case fiveMinutes    = 300
    case tenMinutes     = 600
    case fifteenMinutes = 900
    case oneHour        = 3600
}

// MARK: - Helper methods for accessing Authentication information from the Keychain
public extension KeychainWrapper {
    func authenticationInfo() -> AuthenticationKeychainInfo? {
        NSKeyedUnarchiver.setClass(AuthenticationKeychainInfo.self, forClassName: "AuthenticationKeychainInfo")
        return object(forKey: KeychainKeyAuthenticationInfo) as? AuthenticationKeychainInfo
    }

    func setAuthenticationInfo(_ info: AuthenticationKeychainInfo?) {
        NSKeyedArchiver.setClassName("AuthenticationKeychainInfo", for: AuthenticationKeychainInfo.self)
        if let info = info {
            set(info, forKey: KeychainKeyAuthenticationInfo)
        } else {
            removeObject(forKey: KeychainKeyAuthenticationInfo)
        }
    }
}

open class AuthenticationKeychainInfo: NSObject, NSCoding {
    fileprivate(set) open var lastPasscodeValidationInterval: TimeInterval?
    fileprivate(set) open var passcode: String?
    fileprivate(set) open var requiredPasscodeInterval: PasscodeInterval?
    fileprivate(set) open var lockOutInterval: TimeInterval?
    fileprivate(set) open var failedAttempts: Int
    open var useTouchID: Bool

    // Timeout period before user can retry entering passcodes
    open var lockTimeInterval: TimeInterval = 15 * 60

    public init(passcode: String) {
        self.passcode = passcode
        self.requiredPasscodeInterval = .immediately
        self.failedAttempts = 0
        self.useTouchID = false
    }

    open func encode(with aCoder: NSCoder) {
        if let lastPasscodeValidationInterval = lastPasscodeValidationInterval {
            let interval = NSNumber(value: lastPasscodeValidationInterval as Double)
            aCoder.encode(interval, forKey: "lastPasscodeValidationInterval")
        }

        if let lockOutInterval = lockOutInterval, isLocked() {
            let interval = NSNumber(value: lockOutInterval as Double)
            aCoder.encode(interval, forKey: "lockOutInterval")
        }

        aCoder.encode(passcode, forKey: "passcode")
        aCoder.encode(requiredPasscodeInterval?.rawValue, forKey: "requiredPasscodeInterval")
        aCoder.encode(failedAttempts, forKey: "failedAttempts")
        aCoder.encode(useTouchID, forKey: "useTouchID")
    }

    public required init?(coder aDecoder: NSCoder) {
        self.lastPasscodeValidationInterval = aDecoder.decodeAsDouble(forKey: "lastPasscodeValidationInterval")
        if let lockOutInterval = aDecoder.decodeObject(forKey: "lockOutInterval") as? NSNumber {
            self.lockOutInterval = lockOutInterval.doubleValue
        }
        self.passcode = aDecoder.decodeObject(forKey: "passcode") as? String
        self.failedAttempts = aDecoder.decodeAsInt(forKey: "failedAttempts")
        self.useTouchID = aDecoder.decodeAsBool(forKey: "useTouchID")
        if var interval = aDecoder.decodeObject(forKey: "requiredPasscodeInterval") as? NSNumber {
            // We have updated the immediate lockout value to 2 from 0 due to timing issues with systemUptime()
            interval = interval == 0 ? 2 : interval
            self.requiredPasscodeInterval = PasscodeInterval(rawValue: interval.intValue)
        }
    }
}

// MARK: - API
public extension AuthenticationKeychainInfo {
    private func resetLockoutState() {
        self.failedAttempts = 0
        self.lockOutInterval = nil
    }

    func updatePasscode(_ passcode: String) {
        self.passcode = passcode
        self.lastPasscodeValidationInterval = nil
    }

    func updateRequiredPasscodeInterval(_ interval: PasscodeInterval) {
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
        if self.failedAttempts >= AllowedPasscodeFailedAttempts {
            //This is a failed attempt after a lockout period. Reset the lockout state
            //This prevents failedAttemps from being higher than 3
            self.resetLockoutState()
        }
        self.failedAttempts += 1
    }

    func isLocked() -> Bool {
        guard let lockOutInterval = self.lockOutInterval else {
            return false
        }
        
        if SystemUtils.systemUptime() < lockOutInterval {
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
                  let requireInterval = requiredPasscodeInterval
        else {
            return true
        }

        // We've authenticated before so lets see how long since. If the uptime is less than the last validation stamp,
        // we probably restarted which means we should require validation.
        return SystemUtils.systemUptime() - lastValidationInterval > Double(requireInterval.rawValue) ||
               SystemUtils.systemUptime() < lastValidationInterval
    }
}
