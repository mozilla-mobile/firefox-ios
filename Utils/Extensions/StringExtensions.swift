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
}
