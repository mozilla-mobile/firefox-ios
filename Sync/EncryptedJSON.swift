/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import FxA
import Account
import XCGLogger

private let log = Logger.syncLogger

/**
 * Turns JSON of the form
 *
 *  { ciphertext: ..., hmac: ..., iv: ...}
 *
 * into a new JSON object resulting from decrypting and parsing the ciphertext.
 */
public class EncryptedJSON: JSON {
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
            log.error("Failed to validate.")
            return nil
        }

        let decrypted: String? = keyBundle.decrypt(self.ciphertext, iv: self.iv)
        if (decrypted == nil) {
            log.error("Failed to decrypt.")
            valid = false
            return nil
        }

        _cleartext = JSON.parse(decrypted!)
        return _cleartext!
    }
}