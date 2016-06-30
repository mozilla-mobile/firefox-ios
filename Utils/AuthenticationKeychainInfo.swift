/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import SwiftKeychainWrapper

public let KeychainKeyAuthenticationInfo = "authenticationInfo"
public let AllowedPasscodeFailedAttempts = 3

// Passcode intervals with rawValue in seconds.
public enum PasscodeInterval: Int {
    case Immediately    = 0
    case OneMinute      = 60
    case FiveMinutes    = 300
    case TenMinutes     = 600
    case FifteenMinutes = 900
    case OneHour        = 3600
}

// MARK: - Helper methods for accessing Authentication information from the Keychain
public extension KeychainWrapper {
    class func authenticationInfo() -> AuthenticationKeychainInfo? {
        NSKeyedUnarchiver.setClass(AuthenticationKeychainInfo.self, forClassName: "AuthenticationKeychainInfo")
        return KeychainWrapper.objectForKey(KeychainKeyAuthenticationInfo) as? AuthenticationKeychainInfo
    }

    class func setAuthenticationInfo(info: AuthenticationKeychainInfo?) {
        NSKeyedArchiver.setClassName("AuthenticationKeychainInfo", forClass: AuthenticationKeychainInfo.self)
        if let info = info {
            KeychainWrapper.setObject(info, forKey: KeychainKeyAuthenticationInfo)
        } else {
            KeychainWrapper.removeObjectForKey(KeychainKeyAuthenticationInfo)
        }
    }
}

public class AuthenticationKeychainInfo: NSObject, NSCoding {
    private(set) public var lastPasscodeValidationInterval: NSTimeInterval?
    private(set) public var passcode: String?
    private(set) public var requiredPasscodeInterval: PasscodeInterval?
    private(set) public var lockOutInterval: NSTimeInterval?
    private(set) public var failedAttempts: Int
    public var useAuthenticationForPrivateBrowsing: Bool
    public var useAuthenticationForLogins: Bool

    // Timeout period before user can retry entering passcodes
    public var lockTimeInterval: NSTimeInterval = 15 * 60

    public init(passcode: String) {
        self.passcode = passcode
        self.requiredPasscodeInterval = .Immediately
        self.failedAttempts = 0
        self.useAuthenticationForPrivateBrowsing = true
        self.useAuthenticationForLogins = true
    }

    public func encodeWithCoder(aCoder: NSCoder) {
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
        aCoder.encodeBool(useAuthenticationForPrivateBrowsing, forKey: "useAuthenticationForPrivateBrowsing")
        aCoder.encodeBool(useAuthenticationForLogins, forKey: "useAuthenticationForLogins")
    }

    public required init?(coder aDecoder: NSCoder) {
        self.lastPasscodeValidationInterval = (aDecoder.decodeObjectForKey("lastPasscodeValidationInterval") as? NSNumber)?.doubleValue
        self.lockOutInterval = (aDecoder.decodeObjectForKey("lockOutInterval") as? NSNumber)?.doubleValue
        self.passcode = aDecoder.decodeObjectForKey("passcode") as? String
        self.failedAttempts = aDecoder.decodeIntegerForKey("failedAttempts")
        self.useAuthenticationForPrivateBrowsing = aDecoder.decodeBoolForKey("useAuthenticationForPrivateBrowsing")
        self.useAuthenticationForLogins = aDecoder.decodeBoolForKey("useAuthenticationForLogins")
        if let interval = aDecoder.decodeObjectForKey("requiredPasscodeInterval") as? NSNumber {
            self.requiredPasscodeInterval = PasscodeInterval(rawValue: interval.integerValue)
        }
    }
}

// MARK: - API
public extension AuthenticationKeychainInfo {
    enum AuthenticationPurpose {
        case ModifyAuthenticationSettings
        case PrivateBrowsing
        case Logins
        case Other
    }
    
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
        if (self.failedAttempts >= AllowedPasscodeFailedAttempts) {
            //This is a failed attempt after a lockout period. Reset the lockout state
            //This prevents failedAttemps from being higher than 3
            self.resetLockoutState()
        }
        self.failedAttempts += 1
    }

    func isLocked() -> Bool {
        guard self.lockOutInterval != nil else {
            return false
        }
        if SystemUtils.systemUptime() < self.lockOutInterval {
            // Unlock and require passcode input
            resetLockoutState()
            return false
        }
        return (SystemUtils.systemUptime() - (self.lockOutInterval ?? 0)) < lockTimeInterval
    }

    func requiresValidation(purpose: AuthenticationKeychainInfo.AuthenticationPurpose) -> Bool {
        // If there isn't a passcode, don't need validation.
        guard let _ = passcode else {
            return false
        }
        
        // If the user hasn't turned on authentication for the action they are attempting, don't need validation.
        if purpose == .PrivateBrowsing && !useAuthenticationForPrivateBrowsing
            || purpose == .Logins && !useAuthenticationForLogins {
            return false
        }

        // Need to make sure we've validated in the past. If not, it's a definite yes.
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
