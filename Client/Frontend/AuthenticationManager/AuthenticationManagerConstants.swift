/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared

// Passcode intervals with rawValue in seconds.
enum PasscodeInterval: Int {
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

    case Immediately    = 0
    case OneMinute      = 60
    case FiveMinutes    = 300
    case TenMinutes     = 600
    case FifteenMinutes = 900
    case OneHour        = 3600
}

// Strings used throughout the Authentication Manager
struct AuthenticationStrings {
    static let requirePasscode =
        NSLocalizedString("Require Passcode", tableName: "AuthenticationManager", comment: "Title for setting to require a passcode")

    static let enterAPasscode =
        NSLocalizedString("Enter a passcode", tableName: "AuthenticationManager", comment: "Title above input for entering a passcode")

    static let enterPasscodeTitle =
        NSLocalizedString("Enter Passcode", tableName: "AuthenticationManager", comment: "Screen title for entering a passcode")

    static let enterPasscode =
        NSLocalizedString("Enter passcode", tableName: "AuthenticationManager", comment: "Title above input for entering passcode while removing/changing")

    static let reenterPasscode =
        NSLocalizedString("Re-enter passcode", tableName: "AuthenticationManager", comment: "Title for re-entering a passcode")

    static let setPasscode =
        NSLocalizedString("Set Passcode", tableName: "AuthenticationManager", comment: "Screen title for Set Passcode")

    static let turnOffPasscode =
        NSLocalizedString("Turn Passcode Off", tableName: "AuthenticationManager", comment: "Title for setting to turn off passcode")

    static let turnOnPasscode =
        NSLocalizedString("Turn Passcode On", tableName: "AuthenticationManager", comment: "Title for setting to turn on passcode")

    static let changePasscode =
        NSLocalizedString("Change Passcode", tableName: "AuthenticationManager", comment: "Title for screen when changing your passcode")

    static let enterNewPasscode =
        NSLocalizedString("Enter a new passcode", tableName: "AuthenticationManager", comment: "Title for screen when updating your existin passcode")

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
}