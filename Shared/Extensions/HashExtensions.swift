/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

extension Data {
    public var sha1: Data {
        let len = Int(CC_SHA1_DIGEST_LENGTH)
        let digest = UnsafeMutablePointer<UInt8>.allocate(capacity: len)
        CC_SHA1((self as NSData).bytes, CC_LONG(self.count), digest)
        return Data(bytes: UnsafePointer<UInt8>(digest), count: len)
    }

    public var sha256: Data {
        let len = Int(CC_SHA256_DIGEST_LENGTH)
        let digest = UnsafeMutablePointer<UInt8>.allocate(capacity: len)
        CC_SHA256((self as NSData).bytes, CC_LONG(self.count), digest)
        return Data(bytes: UnsafePointer<UInt8>(digest), count: len)
    }
}

extension String {
    public var sha1: Data {
        let data = self.data(using: .utf8)!
        return data.sha1
    }

    public var sha256: Data {
        let data = self.data(using: .utf8)!
        return data.sha256
    }
}

extension Data {
    public func hmacSha256WithKey(_ key: Data) -> Data {
        let len = Int(CC_SHA256_DIGEST_LENGTH)

        let digest = UnsafeMutablePointer<UInt8>.allocate(capacity: len)
        CCHmac(CCHmacAlgorithm(kCCHmacAlgSHA256),
            (key as NSData).bytes, Int(key.count),
            (self as NSData).bytes, Int(self.count),
            digest)
        return Data(bytes: UnsafePointer<UInt8>(digest), count: len)
    }
}

extension String {
    public var utf8EncodedData: Data {
        return self.data(using: .utf8, allowLossyConversion: false)!
    }
}

extension Data {
    public var utf8EncodedString: String? {
        return String(data: self, encoding: .utf8)
    }
}

