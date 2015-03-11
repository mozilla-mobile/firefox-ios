/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation


extension NSData {
    public var sha1: NSData {
        let len = Int(CC_SHA1_DIGEST_LENGTH)
        var digest = UnsafeMutablePointer<UInt8>.alloc(len)
        CC_SHA1(self.bytes, CC_LONG(self.length), digest)
        return NSData(bytes: UnsafePointer<Void>(digest), length: len)
    }

    public var sha256: NSData {
        let len = Int(CC_SHA256_DIGEST_LENGTH)
        var digest = UnsafeMutablePointer<UInt8>.alloc(len)
        CC_SHA256(self.bytes, CC_LONG(self.length), digest)
        return NSData(bytes: UnsafePointer<Void>(digest), length: len)
    }
}

extension String {
    public var sha1: NSData {
        let data = self.dataUsingEncoding(NSUTF8StringEncoding)!
        return data.sha1
    }

    public var sha256: NSData {
        let data = self.dataUsingEncoding(NSUTF8StringEncoding)!
        return data.sha256
    }
}

extension NSData {
    public func hmacSha256WithKey(key: NSData) -> NSData {
        let len = Int(CC_SHA256_DIGEST_LENGTH)
        var digest = UnsafeMutablePointer<UInt8>.alloc(len)
        CCHmac(CCHmacAlgorithm(kCCHmacAlgSHA256),
            key.bytes, UInt(key.length),
            self.bytes, UInt(self.length),
            digest)
        return NSData(bytes: UnsafePointer<Void>(digest), length: len)
    }
}

extension String {
    public var utf8EncodedData: NSData? {
        return self.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
    }
}
