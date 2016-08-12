/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

public extension String {
    public func contains(other: String) -> Bool {
        // rangeOfString returns nil if other is empty, destroying the analogy with (ordered) sets.
        if other.isEmpty {
            return true
        }
        return self.rangeOfString(other) != nil
    }

    public func startsWith(other: String) -> Bool {
        // rangeOfString returns nil if other is empty, destroying the analogy with (ordered) sets.
        if other.isEmpty {
            return true
        }
        if let range = self.rangeOfString(other,
                options: NSStringCompareOptions.AnchoredSearch) {
            return range.startIndex == self.startIndex
        }
        return false
    }

    public func endsWith(other: String) -> Bool {
        // rangeOfString returns nil if other is empty, destroying the analogy with (ordered) sets.
        if other.isEmpty {
            return true
        }
        if let range = self.rangeOfString(other,
                options: [NSStringCompareOptions.AnchoredSearch, NSStringCompareOptions.BackwardsSearch]) {
            return range.endIndex == self.endIndex
        }
        return false
    }

    func escape() -> String {
        let raw: NSString = self
        let str = CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
            raw,
            "[].", ":/?&=;+!@#$()',*",
            CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding))
        return str as String
    }

    func unescape() -> String {
        let raw: NSString = self
        let str = CFURLCreateStringByReplacingPercentEscapes(kCFAllocatorDefault, raw, "[].")
        return str as String
    }

    /**
    Ellipsizes a String only if it's longer than `maxLength`

      "ABCDEF".ellipsize(4)
      // "AB…EF"

    :param: maxLength The maximum length of the String.

    :returns: A String with `maxLength` characters or less
    */
    func ellipsize(let maxLength maxLength: Int) -> String {
        if (maxLength >= 2) && (self.characters.count > maxLength) {
            let index1 = self.startIndex.advancedBy((maxLength + 1) / 2) // `+ 1` has the same effect as an int ceil
            let index2 = self.endIndex.advancedBy(maxLength / -2)

            return self.substringToIndex(index1) + "…\u{2060}" + self.substringFromIndex(index2)
        }
        return self
    }

    private var stringWithAdditionalEscaping: String {
        return self.stringByReplacingOccurrencesOfString("|", withString: "%7C", options: NSStringCompareOptions(), range: nil)
    }

    public var asURL: NSURL? {
        // Firefox and NSURL disagree about the valid contents of a URL.
        // Let's escape | for them.
        // We'd love to use one of the more sophisticated CFURL* or NSString.* functions, but
        // none seem to be quite suitable.
        return NSURL(string: self) ??
               NSURL(string: self.stringWithAdditionalEscaping)
    }

    /// Returns a new string made by removing the leading String characters contained
    /// in a given character set.
    public func stringByTrimmingLeadingCharactersInSet(set: NSCharacterSet) -> String {
        var trimmed = self
        while trimmed.rangeOfCharacterFromSet(set)?.startIndex == trimmed.startIndex {
            trimmed.removeAtIndex(trimmed.startIndex)
        }
        return trimmed
    }

    /// Adds a newline at the closest space from the middle of a string.
    /// Example turning "Mark as Read" into "Mark as\n Read"
    public func stringSplitWithNewline() -> String {
        let mid = self.characters.count/2

        let arr = self.characters.indices.flatMap { (index) -> Int? in
            if let i = Int("\(index)") where self.characters[index] == " " {
                return i
            }
            return nil
        }
        guard let closest = arr.enumerate().minElement({ abs($0.1 - mid) < abs($1.1 - mid)}) else {
            return self
        }
        var newString = self
        newString.insert("\n", atIndex: newString.characters.startIndex.advancedBy(closest.element))
        return newString
    }
}
