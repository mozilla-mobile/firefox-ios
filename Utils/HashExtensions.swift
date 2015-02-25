/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

extension String {
    public var sha1: NSData {
        let data = self.dataUsingEncoding(NSUTF8StringEncoding)!
        let len = Int(CC_SHA1_DIGEST_LENGTH)
        var digest = UnsafeMutablePointer<UInt8>.alloc(len)
        CC_SHA1(data.bytes, CC_LONG(data.length), digest)
        return NSData(bytes: UnsafePointer<Void>(digest), length: len)
    }

    public var sha256: NSData {
        let data = self.dataUsingEncoding(NSUTF8StringEncoding)!
        let len = Int(CC_SHA256_DIGEST_LENGTH)
        var digest = UnsafeMutablePointer<UInt8>.alloc(len)
        CC_SHA256(data.bytes, CC_LONG(data.length), digest)
        return NSData(bytes: UnsafePointer<Void>(digest), length: len)
    }
}
