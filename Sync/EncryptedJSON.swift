// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation
import Account
import Logger
import Shared
import SwiftyJSON

/**
 * Turns JSON of the form
 *
 *  { ciphertext: ..., hmac: ..., iv: ...}
 *
 * into a new JSON object resulting from decrypting and parsing the ciphertext.
 */
open class EncryptedJSON {
    private var logger: Logger
    var json: JSON
    var _cleartext: JSON?               // Cache decrypted cleartext.
    var _ciphertextBytes: Data?       // Cache decoded ciphertext.
    var _hmacBytes: Data?             // Cache decoded HMAC.
    var _ivBytes: Data?               // Cache decoded IV.

    var valid: Bool = false
    var validated: Bool = false

    let keyBundle: KeyBundle

    public init(json: String, keyBundle: KeyBundle, logger: Logger = DefaultLogger.shared) {
        self.keyBundle = keyBundle
        self.json = JSON(parseJSON: json)
        self.logger = logger
    }

    public init(json: JSON, keyBundle: KeyBundle, logger: Logger = DefaultLogger.shared) {
        self.keyBundle = keyBundle
        self.json = json
        self.logger = logger
    }

    // For validating HMAC: the raw ciphertext as bytes without decoding.
    fileprivate var ciphertextB64: Data? {
        if let cipherText = self["ciphertext"].string {
            return Bytes.dataFromBase64(cipherText)
        }
        return nil
    }

    /**
     * You probably want to call validate() and then use .ciphertext.
     */
    fileprivate var ciphertextBytes: Data? {
        return Bytes.decodeBase64(self["ciphertext"].string!)
    }

    fileprivate func validate() -> Bool {
        if validated {
            return valid
        }

        defer { validated = true }

        guard self["ciphertext"].isString() &&
              self["hmac"].isString() &&
              self["IV"].isString() else {
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
            logger.log("Unable to decode ciphertext base64 in record \(self["id"].string ?? "<unknown>")",
                       level: .warning,
                       category: .sync)
            valid = false
            return false
        }

        self._ciphertextBytes = data
        valid = true
        return valid
    }

    open func isValid() -> Bool {
        return !json.isError() && self.validate()
    }

    /**
     * Make sure you call isValid first. This API force-unwraps for simplicity.
     */
    var ciphertext: Data {
        if _ciphertextBytes != nil {
            return _ciphertextBytes!
        }

        _ciphertextBytes = self.ciphertextBytes
        return _ciphertextBytes!
    }

    var hmac: Data {
        if _hmacBytes != nil {
            return _hmacBytes!
        }
        // NSData(base16EncodedString: self["hmac"].asString!, options: NSDataBase16DecodingOptions.Default)
        _hmacBytes = NSData(base16EncodedString: self["hmac"].stringValue, options: []) as Data
        return _hmacBytes!
    }

    var iv: Data {
        if _ivBytes != nil {
            return _ivBytes!
        }

        _ivBytes = Bytes.decodeBase64(self["IV"].string!)
        return _ivBytes!
    }

    // Returns nil on error.
    open var cleartext: JSON? {
        if _cleartext != nil {
            return _cleartext
        }

        if !isValid() {
            logger.log("Failed to validate encrypted JSON.",
                       level: .warning,
                       category: .sync)
            return nil
        }

        let decrypted: String? = keyBundle.decrypt(self.ciphertext, iv: self.iv)
        if decrypted == nil {
            logger.log("Failed to decrypt encrypted JSON.",
                       level: .warning,
                       category: .sync)
            valid = false
            return nil
        }

        _cleartext = JSON(parseJSON: decrypted!)
        return _cleartext!
    }

    subscript(key: String) -> JSON {
        get {
            return json[key]
        }

        set {
            json[key] = newValue
        }
    }
}
