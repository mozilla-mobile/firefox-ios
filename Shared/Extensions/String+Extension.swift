// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import UIKit

public extension String {
    // Returns hostname from URL
    var titleFromHostname: String {
        guard let displayName = self.asURL?.host  else { return self }
        return displayName
            .replacingOccurrences(of: "^http://", with: "", options: .regularExpression)
            .replacingOccurrences(of: "^https://", with: "", options: .regularExpression)
            .replacingOccurrences(of: "^www\\d*\\.", with: "", options: .regularExpression)
    }

    var asURL: URL? {
        // Firefox and NSURL disagree about the valid contents of a URL.
        // Let's escape | for them.
        // We'd love to use one of the more sophisticated CFURL* or NSString.* functions, but
        // none seem to be quite suitable.
        return URL(string: self) ??
               URL(string: self.stringWithAdditionalEscaping)
    }

    // MARK: - Hashing & Encoding
    var sha1: Data {
        let data = data(using: .utf8)!
        return data.sha1
    }

    var sha256: Data {
        let data = data(using: .utf8)!
        return data.sha256
    }

    var utf8EncodedData: Data {
        return data(using: .utf8, allowLossyConversion: false)!
    }

    func escape() -> String? {
        // We can't guarantee that strings have a valid string encoding, as this is an entry point for tainted data,
        // we should be very careful about forcefully dereferencing optional types.
        // https://stackoverflow.com/questions/33558933/why-is-the-return-value-of-string-addingpercentencoding-optional#33558934
        let queryItemDividers = CharacterSet(charactersIn: "?=&")
        let allowedEscapes = CharacterSet.urlQueryAllowed.symmetricDifference(queryItemDividers)
        return self.addingPercentEncoding(withAllowedCharacters: allowedEscapes)
    }

    func unescape() -> String? {
        return self.removingPercentEncoding
    }

    /**
    Ellipsizes a String only if it's longer than `maxLength`

      "ABCDEF".ellipsize(4)
      // "AB…EF"

    :param: maxLength The maximum length of the String.

    :returns: A String with `maxLength` characters or less
    */
    func ellipsize(maxLength: Int) -> String {
        if (maxLength >= 2) && (self.count > maxLength) {
            let index1 = self.index(self.startIndex, offsetBy: (maxLength + 1) / 2) // `+ 1` has the same effect as an int ceil
            let index2 = self.index(self.endIndex, offsetBy: maxLength / -2)

            return String(self[..<index1]) + "…\u{2060}" + String(self[index2...])
        }
        return self
    }

    /// Returns a new string made by removing the leading String characters contained
    /// in a given character set.
    func stringByTrimmingLeadingCharactersInSet(_ set: CharacterSet) -> String {
        var trimmed = self
        while trimmed.rangeOfCharacter(from: set)?.lowerBound == trimmed.startIndex {
            trimmed.remove(at: trimmed.startIndex)
        }
        return trimmed
    }

    /// Adds a newline at the closest space from the middle of a string.
    /// Example turning "Mark as Read" into "Mark as\n Read"
    func stringSplitWithNewline() -> String {
        let mid = self.count / 2

        let arr: [Int] = self.indices.compactMap {
            if self[$0] == " " {
                return self.distance(from: startIndex, to: $0)
            }

            return nil
        }
        guard let closest = arr.enumerated().min(by: { abs($0.1 - mid) < abs($1.1 - mid) }) else {
            return self
        }
        var newString = self
        newString.insert("\n", at: newString.index(newString.startIndex, offsetBy: closest.element))
        return newString
    }

    func replaceFirstOccurrence(of original: String, with replacement: String) -> String {
        guard let range = self.range(of: original) else {
            return self
        }

        return self.replacingCharacters(in: range, with: replacement)
    }

    func isEmptyOrWhitespace() -> Bool {
        // Check empty string
        if self.isEmpty {
            return true
        }
        // Trim and check empty string
        return self.trimmingCharacters(in: .whitespaces).isEmpty
    }

    /// Find the first match within the given range of the string.
    /// If the regex pattern is valid and there is a match found in the input string,
    /// the method returns the captured substring corresponding to the first capturing group (group index 1) in the regex pattern.
    /// If no match is found or the regex pattern is invalid, the method returns nil.
    func match(_ regex: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: regex) else { return nil }
        let nsString = self as NSString
        let range = NSRange(location: 0, length: nsString.length)
        guard let match = regex.firstMatch(in: self, range: range) else { return nil }
        return nsString.substring(with: match.range(at: 1))
    }

    /// Encode HTMLStrings
    /// Also used for Strings which are not sanitized for displaying
    /// - Returns: Encoded String
    var htmlEntityEncodedString: String {
      return
        self
        .replacingOccurrences(of: "&", with: "&amp;", options: .literal)
        .replacingOccurrences(of: "\"", with: "&quot;", options: .literal)
        .replacingOccurrences(of: "'", with: "&#39;", options: .literal)
        .replacingOccurrences(of: "<", with: "&lt;", options: .literal)
        .replacingOccurrences(of: ">", with: "&gt;", options: .literal)
        .replacingOccurrences(of: "`", with: "&lsquo;", options: .literal)
    }

    // MARK: - Private
    private var stringWithAdditionalEscaping: String {
        return self.replacingOccurrences(of: "|", with: "%7C")
    }
}
