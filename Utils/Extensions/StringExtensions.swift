/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

private let HmacKey = "HMAC"
private let IvKey = "IV"
private let PayloadKey = "Payload"

extension String {
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

    private func sha256(salt: String, payload: String) -> String? {
        if let saltData = salt.dataUsingEncoding(NSUTF8StringEncoding),
            let payloadData = payload.dataUsingEncoding(NSUTF8StringEncoding),
            let hash = NSMutableData(length: Int(CC_SHA256_DIGEST_LENGTH)) {
                let operation: CCOperation = UInt32(kCCHmacAlgSHA256)
                CCHmac(operation, saltData.bytes, saltData.length, payloadData.bytes, payloadData.length, hash.mutableBytes);
                return hash.base64EncodedString
        }

        return nil
    }

    private func performEncryptionOperation(operation: Int, key: NSString, iv: NSData, data: NSData) -> NSData? {
        if let keyData = key.dataUsingEncoding(NSUTF8StringEncoding) {
            let keyBytes = UnsafeMutablePointer<Void>(keyData.bytes)

            let dataLength    = data.length
            let dataBytes     = UnsafePointer<Void>(data.bytes)

            if let cryptData    = NSMutableData(length: Int(dataLength) + kCCBlockSizeAES128) {
                var cryptPointer = UnsafeMutablePointer<Void>(cryptData.mutableBytes)
                let cryptLength  = cryptData.length

                let keyLength              = kCCKeySizeAES256
                let operation: CCOperation = UInt32(operation)
                // Note 128 is the block length here, not the key length
                let algoritm:  CCAlgorithm = UInt32(kCCAlgorithmAES128)
                let options:   CCOptions   = UInt32(kCCModeCBC | kCCOptionPKCS7Padding)

                var numBytesEncrypted: Int = 0
                var cryptStatus = CCCrypt(operation,
                    algoritm,
                    options,
                    keyBytes, keyLength,
                    iv.bytes,
                    dataBytes, dataLength,
                    cryptPointer, cryptLength,
                    &numBytesEncrypted)

                let success: CCCryptorStatus = Int32(kCCSuccess)
                if cryptStatus == success {
                    return cryptData.subdataWithRange(NSRange(location: 0, length: numBytesEncrypted))
                }
            }
        }

        return nil
    }

    private func decodeData(data: NSData) -> (hmac: String, iv: NSMutableData, payload: String)? {
        let decoder = NSKeyedUnarchiver(forReadingWithData: data)
        if let hmac = decoder.decodeObjectForKey(HmacKey) as? String,
           let iv = decoder.decodeObjectForKey(IvKey) as? NSMutableData,
           let payload = decoder.decodeObjectForKey(PayloadKey) as? String {
            decoder.finishDecoding()
            return (hmac, iv, payload)
        }
        return nil
    }

    private func encodeData(hmac: String, iv: NSData, payload: String) -> NSData {
        let data = NSMutableData()
        let encoder = NSKeyedArchiver(forWritingWithMutableData: data)
        encoder.encodeObject(hmac, forKey: HmacKey)
        encoder.encodeObject(iv, forKey: IvKey)
        encoder.encodeObject(payload, forKey: PayloadKey)
        encoder.finishEncoding()
        return data
    }

    public func AES256EncryptWithKey(keyString: String, var iv: NSData? = nil) -> String? {
        if let data = dataUsingEncoding(NSUTF8StringEncoding) {
            if iv == nil {
                if let newIv = NSMutableData(length: 16) {
                    let err = SecRandomCopyBytes(kSecRandomDefault, 16, UnsafeMutablePointer(newIv.mutableBytes))
                    if err != 0 {
                        return nil
                    }
                    iv = newIv
                } else {
                    return nil
                }
            }

            // Short keys make CommonCrypto sad. Running a sha on this one ensures it gets padded up to a reasonable length.
            if let shaKey = sha256(keyString + "Key", payload: keyString),
               let encrypted = performEncryptionOperation(kCCEncrypt, key: shaKey, iv: iv!, data: data) {
                let payload = encrypted.base64EncodedStringWithOptions(NSDataBase64EncodingOptions.allZeros)
                if let hmac = sha256(keyString + "Salt", payload: payload) {
                    let data = encodeData(hmac, iv: iv!, payload: payload)
                    return data.base64EncodedStringWithOptions(NSDataBase64EncodingOptions.allZeros)
                }
            }
        }

        return nil;
    }

    public func AES256DecryptWithKey(keyString: String) -> String? {
        if let data = NSData(base64EncodedString: self as String, options: NSDataBase64DecodingOptions.allZeros),
           let (hmac, iv, payload) = decodeData(data) {

            let localHmac = sha256(keyString + "Salt", payload: payload)
            if localHmac != hmac {
                return nil
            }

            if let payloadData = NSData(base64EncodedString: payload, options: NSDataBase64DecodingOptions.allZeros),
               let shaKey = sha256(keyString + "Key", payload: keyString) {
                if let decrypted = performEncryptionOperation(kCCDecrypt, key: shaKey, iv: iv, data: payloadData) {
                    let str = NSString(data: decrypted, encoding: NSUTF8StringEncoding)
                    return str as? String
                }
            }
        }
        return nil;
    }
}
