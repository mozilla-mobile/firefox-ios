/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared

import SwiftyJSON

public let KeyLength = 32

open class KeyBundle: Hashable {
    public let encKey: Data
    public let hmacKey: Data

    open class func fromKSync(_ kSync: Data) -> KeyBundle {
        return KeyBundle(encKey: kSync.subdata(in: 0..<KeyLength),
                         hmacKey: kSync.subdata(in: KeyLength..<(2 * KeyLength)))
    }

    open class func random() -> KeyBundle {
        // Bytes.generateRandomBytes uses SecRandomCopyBytes, which hits /dev/random, which
        // on iOS is populated by the OS from kernel-level sources of entropy.
        // That should mean that we don't need to seed or initialize anything before calling
        // this. That is probably not true on (some versions of) OS X.
        return KeyBundle(encKey: Bytes.generateRandomBytes(32), hmacKey: Bytes.generateRandomBytes(32))
    }

    open class var invalid: KeyBundle {
        return KeyBundle(encKeyB64: "deadbeef", hmacKeyB64: "deadbeef")!
    }

    public init?(encKeyB64: String, hmacKeyB64: String) {
        guard let e = Bytes.decodeBase64(encKeyB64),
            let h = Bytes.decodeBase64(hmacKeyB64) else {
                return nil
        }
        self.encKey = e
        self.hmacKey = h
    }

    public init(encKey: Data, hmacKey: Data) {
        self.encKey = encKey
        self.hmacKey = hmacKey
    }

    fileprivate func _hmac(_ ciphertext: Data) -> (data: UnsafeMutablePointer<CUnsignedChar>, len: Int) {
        let hmacAlgorithm = CCHmacAlgorithm(kCCHmacAlgSHA256)
        let digestLen = Int(CC_SHA256_DIGEST_LENGTH)
        let result = UnsafeMutablePointer<CUnsignedChar>.allocate(capacity: digestLen)
        CCHmac(hmacAlgorithm, hmacKey.getBytes(), hmacKey.count, ciphertext.getBytes(), ciphertext.count, result)
        return (result, digestLen)
    }

    open func hmac(_ ciphertext: Data) -> Data {
        let (result, digestLen) = _hmac(ciphertext)
        let data = NSMutableData(bytes: result, length: digestLen)

        result.deinitialize(count: digestLen)
        result.deallocate()
        return data as Data
    }

    /**
     * Returns a hex string for the HMAC.
     */
    open func hmacString(_ ciphertext: Data) -> String {
        let (result, digestLen) = _hmac(ciphertext)
        let hash = NSMutableString()
        for i in 0..<digestLen {
            hash.appendFormat("%02x", result[i])
        }

        result.deinitialize(count: digestLen)
        result.deallocate()
        return String(hash)
    }

    open func encrypt(_ cleartext: Data, iv: Data?=nil) -> (ciphertext: Data, iv: Data)? {
        let iv = iv ?? Bytes.generateRandomBytes(16)

        let (success, b, copied) = self.crypt(cleartext, iv: iv, op: CCOperation(kCCEncrypt))
        if success == CCCryptorStatus(kCCSuccess) {
            // Hooray!
            let d = Data(bytes: b, count: Int(copied))
            b.deallocate()
            return (d, iv)
        }

        b.deallocate()
        return nil
    }

    // You *must* verify HMAC before calling this.
    open func decrypt(_ ciphertext: Data, iv: Data) -> String? {
        let (success, b, copied) = self.crypt(ciphertext, iv: iv, op: CCOperation(kCCDecrypt))
        if success == CCCryptorStatus(kCCSuccess) {
            // Hooray!
            let d = Data(bytes: b, count: Int(copied))
            let s = String(data: d, encoding: .utf8)
            b.deallocate()
            return s
        }

        b.deallocate()
        return nil
    }

    fileprivate func crypt(_ input: Data, iv: Data, op: CCOperation) -> (status: CCCryptorStatus, buffer: UnsafeMutableRawPointer, count: Int) {
        let resultSize = input.count + kCCBlockSizeAES128
        var copied: Int = 0
        let result = UnsafeMutableRawPointer.allocate(byteCount: resultSize, alignment: MemoryLayout<Void>.size)

        let success: CCCryptorStatus =
            CCCrypt(op,
                    CCAlgorithm(kCCAlgorithmAES128), // Block size, *NOT* key size
                    CCOptions(kCCOptionPKCS7Padding),
                    encKey.getBytes(),
                    kCCKeySizeAES256,
                    iv.getBytes(),
                    input.getBytes(),
                    input.count,
                    result,
                    resultSize,
                    &copied
        )

        return (success, result, copied)
    }

    open func verify(hmac: Data, ciphertextB64: Data) -> Bool {
        let expectedHMAC = hmac
        let computedHMAC = self.hmac(ciphertextB64)
        return (expectedHMAC == computedHMAC)
    }

    open func asPair() -> [String] {
        return [self.encKey.base64EncodedString, self.hmacKey.base64EncodedString]
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(encKey.base64EncodedString)
        hasher.combine(hmacKey.base64EncodedString)
    }

    public static func ==(lhs: KeyBundle, rhs: KeyBundle) -> Bool {
        return lhs.encKey == rhs.encKey && lhs.hmacKey == rhs.hmacKey
    }
}
