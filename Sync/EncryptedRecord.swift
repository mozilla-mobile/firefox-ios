/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import Storage // Needed for Bytes library
import FxA

public class KeyBundle : Equatable {
    let encKey: NSData;
    let hmacKey: NSData;

    public class func random() -> KeyBundle {
        // Bytes.generateRandomBytes uses SecRandomCopyBytes, which hits /dev/random, which
        // on iOS is populated by the OS from kernel-level sources of entropy.
        // That should mean that we don't need to seed or initialize anything before calling
        // this. That is probably not true on (some versions of) OS X.
        return KeyBundle(encKey: Bytes.generateRandomBytes(32), hmacKey: Bytes.generateRandomBytes(32))
    }

    public class var invalid: KeyBundle {
        return KeyBundle(encKeyB64: "deadbeef", hmacKeyB64: "deadbeef")
    }

    public init(encKeyB64: String, hmacKeyB64: String) {
        self.encKey = Bytes.decodeBase64(encKeyB64)
        self.hmacKey = Bytes.decodeBase64(hmacKeyB64)
    }

    public init(encKey: NSData, hmacKey: NSData) {
        self.encKey = encKey
        self.hmacKey = hmacKey
    }

    private func _hmac(ciphertext: NSData) -> (data: UnsafeMutablePointer<CUnsignedChar>, len: Int) {
        let hmacAlgorithm = CCHmacAlgorithm(kCCHmacAlgSHA256)
        let digestLen: Int = Int(CC_SHA256_DIGEST_LENGTH)
        let result = UnsafeMutablePointer<CUnsignedChar>.alloc(digestLen)
        CCHmac(hmacAlgorithm, hmacKey.bytes, UInt(hmacKey.length), ciphertext.bytes, UInt(ciphertext.length), result)
        return (result, digestLen)
    }

    public func hmac(ciphertext: NSData) -> NSData {
        let (result, digestLen) = _hmac(ciphertext)
        var data = NSMutableData(bytes: result, length: digestLen)

        result.destroy()
        return data
    }

    /**
     * Returns a hex string for the HMAC.
     */
    public func hmacString(ciphertext: NSData) -> String {
        let (result, digestLen) = _hmac(ciphertext)
        var hash = NSMutableString()
        for i in 0..<digestLen {
            hash.appendFormat("%02x", result[i])
        }

        result.destroy()
        return String(hash)
    }

    public func encrypt(cleartext: NSData, iv: NSData?=nil) -> (ciphertext: NSData, iv: NSData)? {
        let iv = iv ?? Bytes.generateRandomBytes(16)

        let (success, b, copied) = self.crypt(cleartext, iv: iv, op: CCOperation(kCCEncrypt))
        if success == CCCryptorStatus(kCCSuccess) {
            // Hooray!
            let d = NSData(bytes: b, length: Int(copied))
            b.destroy()
            return (d, iv)
        }

        b.destroy()
        return nil
    }

    // You *must* verify HMAC before calling this.
    public func decrypt(ciphertext: NSData, iv: NSData) -> String? {
        let (success, b, copied) = self.crypt(ciphertext, iv: iv, op: CCOperation(kCCDecrypt))
        if success == CCCryptorStatus(kCCSuccess) {
            // Hooray!
            let d = NSData(bytesNoCopy: b, length: Int(copied))
            let s = NSString(data: d, encoding: NSUTF8StringEncoding)
            b.destroy()
            return s
        }

        b.destroy()
        return nil
    }


    private func crypt(input: NSData, iv: NSData, op: CCOperation) -> (status: CCCryptorStatus, buffer: UnsafeMutablePointer<CUnsignedChar>, count: UInt) {
        let resultSize = input.length + kCCBlockSizeAES128
        let result = UnsafeMutablePointer<CUnsignedChar>.alloc(resultSize)
        var copied: UInt = 0

        let success: CCCryptorStatus =
        CCCrypt(op,
                CCHmacAlgorithm(kCCAlgorithmAES128),
                CCOptions(kCCOptionPKCS7Padding),
                encKey.bytes,
                UInt(kCCKeySizeAES256),
                iv.bytes,
                input.bytes,
                UInt(input.length),
                result,
                UInt(resultSize),
                &copied
        );

        return (success, result, copied)
    }

    public func verify(#hmac: NSData, ciphertextB64: NSData) -> Bool {
        let expectedHMAC = hmac
        let computedHMAC = self.hmac(ciphertextB64)
        return expectedHMAC.isEqualToData(computedHMAC)
    }
    
    public func factory<T : CleartextPayloadJSON>() -> (String) -> T? {
        return { (payload: String) -> T? in
            let potential = EncryptedJSON(json: payload, keyBundle: self)
            if !(potential.isValid()) {
                return nil
            }
            
            let cleartext = potential.cleartext
            if (cleartext == nil) {
                return nil
            }
            return T(cleartext!)
        }
    }
}

public func == (lhs: KeyBundle, rhs: KeyBundle) -> Bool {
    return lhs.encKey.isEqualToData(rhs.encKey) &&
           lhs.hmacKey.isEqualToData(rhs.hmacKey)
}

public class Keys {
    let valid: Bool
    let defaultBundle: KeyBundle
    var collectionKeys: [String: KeyBundle] = [String: KeyBundle]()

    public init(defaultBundle: KeyBundle) {
        self.defaultBundle = defaultBundle
        self.valid = true
    }

    public init(downloaded: EnvelopeJSON, master: KeyBundle) {
        let keysRecord = Record<KeysPayload>.fromEnvelope(downloaded, payloadFactory: master.factory())
        if let payload: KeysPayload = keysRecord?.payload {
            if payload.isValid() && payload.defaultKeys != nil {
                self.defaultBundle = payload.defaultKeys!
                self.valid = true
                return
            }

            self.defaultBundle = KeyBundle.invalid
            self.valid = false
            return
        }

        self.defaultBundle = KeyBundle.invalid
        self.valid = true
    }

    public func forCollection(collection: String) -> KeyBundle {
        if let bundle = collectionKeys[collection] {
            return bundle
        }
        return defaultBundle
    }

    public func factory<T : CleartextPayloadJSON>(collection: String) -> (String) -> T? {
        let bundle = forCollection(collection)
        return bundle.factory()
    }
}

/**
 * Turns JSON of the form
 *
 *  { ciphertext: ..., hmac: ..., iv: ...}
 *
 * into a new JSON object resulting from decrypting and parsing the ciphertext.
 */
public class EncryptedJSON : JSON {
    var _cleartext: JSON?               // Cache decrypted cleartext.
    var _ciphertextBytes: NSData?       // Cache decoded ciphertext.
    var _hmacBytes: NSData?             // Cache decoded HMAC.
    var _ivBytes: NSData?               // Cache decoded IV.

    var valid: Bool = false
    var validated: Bool = false

    let keyBundle: KeyBundle

    public init(json: String, keyBundle: KeyBundle) {
        self.keyBundle = keyBundle
        super.init(JSON.parse(json))
    }
    
    public init(json: JSON, keyBundle: KeyBundle) {
        self.keyBundle = keyBundle
        super.init(json)
    }
    
    private func validate() -> Bool {
        if validated {
            return valid
        }

        valid = self["ciphertext"].isString &&
                self["hmac"].isString &&
                self["IV"].isString
        if (!valid) {
            validated = true
            return false
        }

        validated = true
        if let ciphertextForHMAC = self.ciphertextB64 {
            return keyBundle.verify(hmac: self.hmac, ciphertextB64: ciphertextForHMAC)
        } else {
            return false
        }
    }

    public func isValid() -> Bool {
        return !isError &&
               self.validate()
    }

    func fromBase64(str: String) -> NSData {
        let b = Bytes.decodeBase64(str)
        println("Base64 \(str) yielded \(b)")
        return b
    }

    var ciphertextB64: NSData? {
        if let ct = self["ciphertext"].asString {
            return Bytes.dataFromBase64(ct)
        } else {
            return nil
        }
    }

    var ciphertext: NSData {
        if (_ciphertextBytes != nil) {
            return _ciphertextBytes!
        }

        _ciphertextBytes = fromBase64(self["ciphertext"].asString!)
        return _ciphertextBytes!
    }
    
    var hmac: NSData {
        if (_hmacBytes != nil) {
            return _hmacBytes!
        }
            
        _hmacBytes = NSData(base16EncodedString: self["hmac"].asString!, options: NSDataBase16DecodingOptions.Default)
        return _hmacBytes!
    }

    var iv: NSData {
        if (_ivBytes != nil) {
            return _ivBytes!
        }
            
        _ivBytes = fromBase64(self["IV"].asString!)
        return _ivBytes!
    }

    // Returns nil on error.
    public var cleartext: JSON? {
        if (_cleartext != nil) {
            return _cleartext
        }

        if (!validate()) {
            println("Failed to validate.")
            return nil
        }

        let decrypted: String? = keyBundle.decrypt(self.ciphertext, iv: self.iv)
        if (decrypted == nil) {
            println("Failed to decrypt.")
            valid = false
            return nil
        }

        _cleartext = JSON.parse(decrypted!)
        return _cleartext!
    }
}