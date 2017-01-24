/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation


extension NSData {
    public var sha1: NSData {
        let len = Int(CC_SHA1_DIGEST_LENGTH)
        let digest = UnsafeMutablePointer<UInt8>.alloc(len)
        CC_SHA1(self.bytes, CC_LONG(self.length), digest)
        return NSData(bytes: UnsafePointer<Void>(digest), length: len)
    }

    public var sha256: NSData {
        let len = Int(CC_SHA256_DIGEST_LENGTH)
        let digest = UnsafeMutablePointer<UInt8>.alloc(len)
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
        let digest = UnsafeMutablePointer<Void>.alloc(len)
        CCHmac(CCHmacAlgorithm(kCCHmacAlgSHA256),
            key.bytes, Int(key.length),
            self.bytes, Int(self.length),
            digest)
        return NSData(bytes: UnsafePointer<Void>(digest), length: len)
    }
}

extension String {
    public var utf8EncodedData: NSData {
        return self.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!
    }
}

extension NSData {
    public var utf8EncodedString: String? {
        return NSString(data: self, encoding: NSUTF8StringEncoding) as String?
    }
}

extension NSData {
    public func xoredWith(other: NSData) -> NSData? {
        if self.length != other.length {
            return nil
        }
        var xoredBytes = [UInt8](count: self.length, repeatedValue: 0)
        let selfBytes = UnsafePointer<UInt8>(self.bytes)
        let otherBytes = UnsafePointer<UInt8>(other.bytes)
        for i in 0..<self.length {
            xoredBytes[i] = selfBytes[i] ^ otherBytes[i]
        }
        return NSData(bytes: xoredBytes, length: self.length)
    }

}
