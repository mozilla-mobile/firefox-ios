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

    // For validating HMAC: the raw ciphertext as bytes without decoding.
    private var ciphertextB64: NSData? {
        if let ct = self["ciphertext"].asString {
            return Bytes.dataFromBase64(ct)
        }
        return nil
    }

    /**
     * You probably want to call validate() and then use .ciphertext.
     */
    private var ciphertextBytes: NSData? {
        return Bytes.decodeBase64(self["ciphertext"].asString!)
    }

    private func validate() -> Bool {
        if validated {
            return valid
        }

        defer { validated = true }

        guard self["ciphertext"].isString &&
              self["hmac"].isString &&
              self["IV"].isString else {
            valid = false
            return false
        }

        guard let ciphertextForHMAC = self.ciphertextB64 else {
            valid = false
            return false
        }

        guard keyBundle.verify(hmac: self.hmac, ciphertextB64: ciphertextForHMAC) else {
            valid = false
            return false
        }

        // I guess we called validate twice…
        if self._ciphertextBytes != nil {
            valid = true
            return true
        }

        // Also verify that the ciphertext is valid base64. Do this by
        // retrieving the value in a failable way, leaving the accessors
        // to take the dangerous/simple path.
        // We can force-unwrap self["ciphertext"] because we already checked
        // it when verifying the HMAC above.
        guard let data = self.ciphertextBytes else {
            log.error("Unable to decode ciphertext base64 in record \(self["id"].asString ?? "<unknown>")")
            valid = false
            return false
        }

        self._ciphertextBytes = data
        valid = true
        return valid
    }

    public func isValid() -> Bool {
        return !isError && self.validate()
    }

    /**
     * Make sure you call isValid first. This API force-unwraps for simplicity.
     */
    var ciphertext: NSData {
        if (_ciphertextBytes != nil) {
            return _ciphertextBytes!
        }

        _ciphertextBytes = self.ciphertextBytes
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

        _ivBytes = Bytes.decodeBase64(self["IV"].asString!)
        return _ivBytes!
    }

    // Returns nil on error.
    public var cleartext: JSON? {
        if (_cleartext != nil) {
            return _cleartext
        }

        if (!isValid()) {
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
