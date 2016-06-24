/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared

// Strings for the passcode intervals.
extension PasscodeInterval {
    var settingTitle: String {
        switch self {
        case .Immediately:      return AuthenticationStrings.immediately
        case .OneMinute:        return AuthenticationStrings.oneMinute
        case .FiveMinutes:      return AuthenticationStrings.fiveMinutes
        case .TenMinutes:       return AuthenticationStrings.tenMinutes
        case .FifteenMinutes:   return AuthenticationStrings.fifteenMinutes
        case .OneHour:          return AuthenticationStrings.oneHour
        }
    }
}

// Strings used in multiple areas within the Authentication Manager
struct AuthenticationStrings {
    static let passcode =
        NSLocalizedString("Passcode", tableName: "AuthenticationManager", comment: "Label for the Passcode item in Settings")
    
    static let touchID =
        NSLocalizedString("Use Touch ID to access:", tableName: "AuthenticationManager", comment: "Label for the Touch ID-related items in Settings")

    static let touchIDPasscodeSetting =
        NSLocalizedString("Touch ID & Passcode", tableName: "AuthenticationManager", comment: "Label for the Touch ID/Passcode item in Settings")

    static let requirePasscode =
        NSLocalizedString("Require Passcode", tableName: "AuthenticationManager", comment: "Text displayed in the 'Interval' section, followed by the current interval setting, e.g. 'Immediately'")

    static let enterAPasscode =
        NSLocalizedString("Enter a passcode", tableName: "AuthenticationManager", comment: "Text displayed above the input field when entering a new passcode")

    static let enterPasscodeTitle =
        NSLocalizedString("Enter Passcode", tableName: "AuthenticationManager", comment: "Title of the dialog used to request the passcode")

    static let enterPasscode =
        NSLocalizedString("Enter passcode", tableName: "AuthenticationManager", comment: "Text displayed above the input field when changing the existing passcode")

    static let reenterPasscode =
        NSLocalizedString("Re-enter passcode", tableName: "AuthenticationManager", comment: "Text displayed above the input field when confirming a passcode")

    static let setPasscode =
        NSLocalizedString("Set Passcode", tableName: "AuthenticationManager", comment: "Title of the dialog used to set a passcode")

    static let turnOffPasscode =
        NSLocalizedString("Turn Passcode Off", tableName: "AuthenticationManager", comment: "Label used as a setting item to turn off passcode")

    static let turnOnPasscode =
        NSLocalizedString("Turn Passcode On", tableName: "AuthenticationManager", comment: "Label used as a setting item to turn on passcode")

    static let changePasscode =
        NSLocalizedString("Change Passcode", tableName: "AuthenticationManager", comment: "Label used as a setting item and title of the following screen to change the current passcode")

    static let enterNewPasscode =
        NSLocalizedString("Enter a new passcode", tableName: "AuthenticationManager", comment: "Text displayed above the input field when changing the existing passcode")

    static let immediately =
        NSLocalizedString("Immediately", tableName: "AuthenticationManager", comment: "'Immediately' interval item for selecting when to require passcode")

    static let oneMinute =
        NSLocalizedString("After 1 minute", tableName: "AuthenticationManager", comment: "'After 1 minute' interval item for selecting when to require passcode")

    static let fiveMinutes =
        NSLocalizedString("After 5 minutes", tableName: "AuthenticationManager", comment: "'After 5 minutes' interval item for selecting when to require passcode")

    static let tenMinutes =
        NSLocalizedString("After 10 minutes", tableName: "AuthenticationManager", comment: "'After 10 minutes' interval item for selecting when to require passcode")

    static let fifteenMinutes =
        NSLocalizedString("After 15 minutes", tableName: "AuthenticationManager", comment: "'After 15 minutes' interval item for selecting when to require passcode")

    static let oneHour =
        NSLocalizedString("After 1 hour", tableName: "AuthenticationManager", comment: "'After 1 hour' interval item for selecting when to require passcode")

    static let loginsTouchReason =
        NSLocalizedString("Use your fingerprint to access Logins now.", tableName: "AuthenticationManager", comment: "Touch ID prompt subtitle when accessing logins")
    
    static let privateModeReason =
        NSLocalizedString("Use your fingerprint to start browsing privately.", tableName: "AuthenticationManager", comment: "Touch ID prompt subtitle when entering private mode")

    static let requirePasscodeTouchReason =
        NSLocalizedString("touchid.require.passcode.reason.label",
                          value: "Use your fingerprint to access configuring your required passcode interval.",
                          tableName: "AuthenticationManager",
                          comment: "Touch ID prompt subtitle when accessing the require passcode setting")

    static let disableTouchReason =
        NSLocalizedString("touchid.disable.reason.label",
                          value: "Use your fingerprint to disable Touch ID.",
                          tableName: "AuthenticationManager",
                          comment: "Touch ID prompt subtitle when disabling Touch ID")

    static let wrongPasscodeError =
        NSLocalizedString("Incorrect passcode. Try again.", tableName: "AuthenticationManager", comment: "Error message displayed when user enters incorrect passcode when trying to enter a protected section of the app")

    static let incorrectAttemptsRemaining =
        NSLocalizedString("Incorrect passcode. Try again (Attempts remaining: %d).", tableName: "AuthenticationManager", comment: "Error message displayed when user enters incorrect passcode when trying to enter a protected section of the app with attempts remaining")

    static let maximumAttemptsReached =
        NSLocalizedString("Maximum attempts reached. Please try again in an hour.", tableName: "AuthenticationManager", comment: "Error message displayed when user enters incorrect passcode and has reached the maximum number of attempts.")

    static let maximumAttemptsReachedNoTime =
        NSLocalizedString("Maximum attempts reached. Please try again later.", tableName: "AuthenticationManager", comment: "Error message displayed when user enters incorrect passcode and has reached the maximum number of attempts.")
}
