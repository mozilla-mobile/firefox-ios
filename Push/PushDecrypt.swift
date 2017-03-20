/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import FxA

/// Class to wrap ece.c which does the decryption with OpenSSL.
/// This supports aes128gcm and aesgcm.
/// This will also support the generation of keys to register with a push server.
class PushDecrypt {
    func aes128gcm(payload data: String, decryptWith privateKey: String, authenticateWith authKey: String) throws -> String {
        var authSecret = try stringToBuffer(authKey)
        var rawRecvPrivKey = try stringToBuffer(privateKey)
        var plaintext = emptyBuffer()
        var payload = try stringToBuffer(data)

        defer {
            ece_buf_free(&authSecret)
            ece_buf_free(&rawRecvPrivKey)
            ece_buf_free(&payload)
            ece_buf_free(&plaintext)
        }

        let err =
            ece_aes128gcm_decrypt(&rawRecvPrivKey, &authSecret, &payload, &plaintext)
        if (err != 0) {
            throw PushDecryptError.cantDecrypt
        }
        
        return try bufferToString(plaintext)
    }

    func aesgcm(ciphertext data: String, decryptWith privateKey: String, authenticateWith authKey: String, encryptionHeader: String, cryptoKeyHeader: String) throws -> String {

        var authSecret = try stringToBuffer(authKey)
        var rawRecvPrivKey = try stringToBuffer(privateKey)
        var plaintext = emptyBuffer()
        var ciphertext = try stringToBuffer(data)

        defer {
            ece_buf_free(&authSecret)
            ece_buf_free(&rawRecvPrivKey)
            ece_buf_free(&ciphertext)
            ece_buf_free(&plaintext)
        }

        let err = ece_aesgcm_decrypt(&rawRecvPrivKey, &authSecret, cryptoKeyHeader,
                           encryptionHeader, &ciphertext, &plaintext)
        if (err != 0) {
            throw PushDecryptError.cantDecrypt
        }

        return try bufferToString(plaintext)
    }
}

/// Some utility methods that make package up dealing with the C API a little easier.
extension PushDecrypt {
    func emptyBuffer() -> ece_buf_t {
        var bytes = [UInt8]()
        return ece_buf_t(bytes: &bytes, length: 0)
    }

    /// Converts a Swift string into a ece_buf_t. It assumes that the String is base64 encoded.
    func stringToBuffer(_ string: String) throws -> ece_buf_t {
        var cstring = [UInt8](string.utf8).map { Int8($0) }
        var buffer = emptyBuffer()
        // Using ece_base64url_decode with REJECT_PADDING
        // is a quicker way to get to ece_buf_t than using Data(base64Encoded:,options:)
        ece_base64url_decode(&cstring, cstring.count, ECE_BASE64URL_REJECT_PADDING, &buffer)

        return buffer
    }

    func bufferToString(_ buffer: ece_buf_t) throws -> String {
        guard let bytes = buffer.bytes else {
            throw PushDecryptError.zeroBytes
        }
        let data = Data(bytes: bytes, count: buffer.length)
        return data.utf8EncodedString!
    }

    func dataToBuffer(_ data: Data) -> ece_buf_t {
        var bytes = data.getBytes()
        return ece_buf_t(bytes: &bytes, length: bytes.count)
    }
}

enum PushDecryptError: Error {
    case cantBase64Decode
    case cantDecrypt
    case zeroBytes
}
