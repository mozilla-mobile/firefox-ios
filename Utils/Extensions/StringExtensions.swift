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

    public var asURL: NSURL? {
        return NSURL(string: self)
    }

    private func encrypt(operation: Int, key: NSString, data: NSData) -> NSData? {
        let keyData: NSData! = (key as NSString).dataUsingEncoding(NSUTF8StringEncoding) as NSData!
        let keyBytes         = UnsafePointer<Void>(keyData.bytes)

        let dataLength    = data.length
        let dataBytes     = UnsafePointer<Void>(data.bytes)

        let cryptData    = NSMutableData(length: Int(dataLength) + kCCBlockSizeAES128)
        var cryptPointer = UnsafeMutablePointer<Void>(cryptData!.mutableBytes)
        let cryptLength  = cryptData!.length

        let keyLength              = kCCKeySizeAES256
        let operation: CCOperation = UInt32(operation)
        let algoritm:  CCAlgorithm = UInt32(kCCAlgorithmAES128)
        let options:   CCOptions   = UInt32(kCCOptionECBMode + kCCOptionPKCS7Padding)

        var numBytesEncrypted: Int = 0
        let iv = UnsafePointer<Void>()

        var cryptStatus = CCCrypt(operation,
            algoritm,
            options,
            keyBytes, keyLength,
            iv,
            dataBytes, dataLength,
            cryptPointer, cryptLength,
            &numBytesEncrypted)

        let success: CCCryptorStatus = Int32(kCCSuccess)
        if cryptStatus == success {
            return cryptData!.subdataWithRange(NSRange(location: 0, length: numBytesEncrypted))
        }

        return nil;
    }

    public func AES128EncryptWithKey(keyString: String) -> String? {
        let data: NSData! = dataUsingEncoding(NSUTF8StringEncoding) as NSData!
        if let encrypted = encrypt(kCCEncrypt, key: keyString, data: data) {
            return encrypted.base64EncodedString
        }

        return nil;
    }

    public func AES128DecryptWithKey(keyString: String) -> String? {
        let data: NSData! = NSData(base64EncodedString: self as String, options: NSDataBase64DecodingOptions())
        if let decrypted = encrypt(kCCDecrypt, key: keyString, data: data) {
            println("Decrypting \(self) as \(NSString(data: decrypted, encoding: NSUTF8StringEncoding))")
            return NSString(data: decrypted, encoding: NSUTF8StringEncoding) as? String
        }
        
        return nil;
    }
}
