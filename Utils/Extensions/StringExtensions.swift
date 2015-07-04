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
                options: NSStringCompareOptions.AnchoredSearch | NSStringCompareOptions.BackwardsSearch) {
            return range.endIndex == self.endIndex
        }
        return false
    }

    func escape() -> String {
        var raw: NSString = self
        var str = CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
            raw,
            "[].",":/?&=;+!@#$()',*",
            CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding))
        return str as! String
    }

    func unescape() -> String {
        var raw: NSString = self
        var str = CFURLCreateStringByReplacingPercentEscapes(kCFAllocatorDefault, raw, "[].")
        return str as! String
    }

    public var asURL: NSURL? {
        return NSURL(string: self)
    }

    /*
     * A string with an ellipsis needs at least a length of 3 - first element, ellipsis, last element. Anything less than 3 should just return an ellipsis by itself
     * The string can't be shorter than the length it's being truncated to. In case of this, no ellipsis will be added.
     * When the truncatedLength is even, the character at length / 2 + 1 is replaced with the ellipsis.
     * When the truncatedLength is odd, the middle character is replaced.
     */
    public func ellipsize(truncatedLength: Int) -> String {
        if count(self) < truncatedLength {
            return self
        }
        if truncatedLength < 3 {
            return "…"
        }
        let offsetForEven = truncatedLength % 2 == 0 ? 1 : 0
        return self[self.startIndex..<advance(self.startIndex, truncatedLength / 2)] + "…" + self[advance(self.endIndex, truncatedLength / -2 + offsetForEven)..<self.endIndex]
    }
}
