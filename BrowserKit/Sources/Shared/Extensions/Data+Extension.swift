// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

extension Data {
    public var sha1: Data {
        let length = Int(CC_SHA1_DIGEST_LENGTH)
        let digest = UnsafeMutablePointer<UInt8>.allocate(capacity: length)
        CC_SHA1((self as NSData).bytes, CC_LONG(self.count), digest)
        return Data(bytes: UnsafePointer<UInt8>(digest), count: length)
    }

    public var sha256: Data {
        let length = Int(CC_SHA256_DIGEST_LENGTH)
        let digest = UnsafeMutablePointer<UInt8>.allocate(capacity: length)
        CC_SHA256((self as NSData).bytes, CC_LONG(self.count), digest)
        return Data(bytes: UnsafePointer<UInt8>(digest), count: length)
    }

    public func hmacSha256WithKey(_ key: Data) -> Data {
        let length = Int(CC_SHA256_DIGEST_LENGTH)

        let digest = UnsafeMutablePointer<UInt8>.allocate(capacity: length)
        CCHmac(
            CCHmacAlgorithm(kCCHmacAlgSHA256),
            (key as NSData).bytes,
            Int(key.count),
            (self as NSData).bytes,
            Int(self.count),
            digest)
        return Data(bytes: UnsafePointer<UInt8>(digest), count: length)
    }

    public var utf8EncodedString: String? {
        return String(data: self, encoding: .utf8)
    }
}
