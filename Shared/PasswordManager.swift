// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

// MARK: - PasswordManager

/// Class for handling the creation (and eventually other uses) of secure passwords.
public class PasswordManager {

    /// Generates a new, secure password.
    /// The password format is modeled after Apple's securely-generated passwords:
    /// xxxxxx-xxxxxx-xxxxxx
    /// where one x is an uppercase letter, one x is a numeric digit, and the rest are lowercase letters.
    public static func generateSecurePassword() -> String {
        let numberOfAlphanumericPositions = 18
        let separatorPositions = [6, 13]
        var capitalLetterPosition = Int.random(in: 0..<numberOfAlphanumericPositions)
        var numberPosition = Int.random(in: 0..<numberOfAlphanumericPositions)

        // If capitalLetterPosition and numberPosition are the same, pick a new numberPosition
        while capitalLetterPosition == numberPosition {
            numberPosition = Int.random(in: 0..<numberOfAlphanumericPositions)
        }

        capitalLetterPosition.adjustForPasswordDashes()
        numberPosition.adjustForPasswordDashes()

        let lowercaseLetters = "abcdefghijklmnopqrstuvwxyz"
        let uppercaseLetters = lowercaseLetters.uppercased()

        var password = ""
        for index in 0..<20 {
            switch index {
            case capitalLetterPosition: password.append(uppercaseLetters.randomElement()!)
            case numberPosition: password.append("\(Int.random(in: 0...9))")
            case let x where separatorPositions.contains(x): password.append("-")
            default: password.append(lowercaseLetters.randomElement()!)
            }
        }

        return password
    }
}

extension Int {
    /// Helper function that shifts an int to account for dashes in passwords
    /// with the format xxxxxx-xxxxxx-xxxxxx.
    fileprivate mutating func adjustForPasswordDashes() {
        switch self {
        case 12...: self += 2
        case 6...11: self += 1
        default: return
        }
    }
}
