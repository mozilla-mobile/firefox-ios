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
        return URL(string: self, invalidCharacters: false) ??
               URL(string: self.stringWithAdditionalEscaping, invalidCharacters: false)
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
    /// the method returns the captured substring corresponding to the first capturing
    /// group (group index 1) in the regex pattern.
    /// If no match is found or the regex pattern is invalid, the method returns nil.
    func match(_ regex: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: regex) else { return nil }
        let nsString = self as NSString
        let range = NSRange(location: 0, length: nsString.length)
        guard let match = regex.firstMatch(in: self, range: range) else { return nil }
        return nsString.substring(with: match.range(at: 1))
    }

    /// Returning a dictionary [String: String] from string format: "Key1<valueSeparator> Value1<keySeparator>, ..."
    func getDictionary(keySeparator: Character = ",", valueSeparator: Character = "=") -> [String: String] {
        var result = [String: String]()
        let components = self.split(separator: keySeparator)
        for component in components {
            let parts = component.split(separator: valueSeparator, maxSplits: 1, omittingEmptySubsequences: false)
            if parts.count == 2 {
                let key = parts[0].trimmingCharacters(in: .whitespacesAndNewlines)
                let value = parts[1].trimmingCharacters(in: .whitespacesAndNewlines)
                result[key] = value
            }
        }
        return result
    }

    // MARK: - Private
    private var stringWithAdditionalEscaping: String {
        return self.replacingOccurrences(of: "|", with: "%7C")
    }
}
