/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import FxA

/// Class to wrap ecec which does the encryption, decryption and key generation with OpenSSL.
/// This supports aesgcm and the newer aes128gcm.
/// For each standard of decryption, two methods are supplied: one with Data parameters and return value, 
/// and one with a String based one.
class PushCrypto {
    // Stateless, we provide a singleton for convenience.
    open static var sharedInstance = PushCrypto()
}

// AES128GCM
// Both encryption and decryption are supported.
extension PushCrypto {
    func aes128gcm(payload data: String, decryptWith privateKey: String, authenticateWith authKey: String) throws -> String {
        guard let authSecret = authKey.base64urlSafeDecodedData,
            let rawRecvPrivKey = privateKey.base64urlSafeDecodedData,
            let payload = data.base64urlSafeDecodedData else {
                throw PushCryptoError.base64DecodeError
        }

        let decrypted = try aes128gcm(payload: payload,
                             decryptWith: rawRecvPrivKey,
                             authenticateWith: authSecret)

        guard let plaintext = decrypted.utf8EncodedString else {
            throw PushCryptoError.utf8EncodingError
        }

        return plaintext
    }

    func aes128gcm(payload: Data, decryptWith rawRecvPrivKey: Data, authenticateWith authSecret: Data) throws -> Data {
        var plaintextLen = ece_aes128gcm_plaintext_max_length(payload.getBytes(), payload.count) + 1
        var plaintext = [UInt8](repeating: 0, count: plaintextLen)

        let err = ece_webpush_aes128gcm_decrypt(
                rawRecvPrivKey.getBytes(), rawRecvPrivKey.count,
                authSecret.getBytes(), authSecret.count,
                payload.getBytes(), payload.count,
                &plaintext, &plaintextLen)

        if err != ECE_OK {
            throw PushCryptoError.decryptionError(errCode: err)
        }
        
        return Data(bytes: plaintext, count: plaintextLen)
    }

    func aes128gcm(plaintext: String, encryptWith rawRecvPubKey: String, authenticateWith authSecret: String, rs: Int, padLen: Int) throws -> String {
        guard let rawRecvPubKey = rawRecvPubKey.base64urlSafeDecodedData,
            let authSecret = authSecret.base64urlSafeDecodedData else {
                throw PushCryptoError.base64DecodeError
        }

        let plaintextData = plaintext.utf8EncodedData

        let payloadData = try aes128gcm(plaintext: plaintextData,
                                    encryptWith: rawRecvPubKey,
                                    authenticateWith: authSecret,
                                    rs: rs, padLen: padLen)

        return payloadData.base64urlSafeEncodedString
    }

    func aes128gcm(plaintext: Data, encryptWith rawRecvPubKey: Data, authenticateWith authSecret: Data, rs rsInt: Int, padLen: Int) throws -> Data {
        let rs = UInt32(rsInt)

        // rs needs to be >= 18.
        assert(rsInt >= Int(ECE_AES128GCM_MIN_RS))
        var payloadLen = ece_aes128gcm_payload_max_length(rs, padLen, plaintext.count) + 1
        var payload = [UInt8](repeating: 0, count: payloadLen)

        let err = ece_aes128gcm_encrypt(rawRecvPubKey.getBytes(), rawRecvPubKey.count,
                                    authSecret.getBytes(), authSecret.count,
                                    rs, padLen,
                                    plaintext.getBytes(), plaintext.count,
                                    &payload, &payloadLen)
        if err != ECE_OK {
            throw PushCryptoError.encryptionError(errCode: err)
        }

        return Data(bytes: payload, count: payloadLen)
    }
}

// AESGCM
// Encryption is not supported.
extension PushCrypto {
    func aesgcm(ciphertext data: String, decryptWith privateKey: String, authenticateWith authKey: String, encryptionHeader: String, cryptoKeyHeader: String) throws -> String {
        guard let authSecret = authKey.base64urlSafeDecodedData,
            let rawRecvPrivKey = privateKey.base64urlSafeDecodedData,
            let ciphertext = data.base64urlSafeDecodedData else {
                throw PushCryptoError.base64DecodeError
        }

        let decrypted = try aesgcm(ciphertext: ciphertext,
                          decryptWith: rawRecvPrivKey,
                          authenticateWith: authSecret,
                          encryptionHeader: encryptionHeader,
                          cryptoKeyHeader: cryptoKeyHeader)

        guard let plaintext = decrypted.utf8EncodedString else {
            throw PushCryptoError.utf8EncodingError
        }

        return plaintext
    }

    func aesgcm(ciphertext: Data, decryptWith rawRecvPrivKey: Data, authenticateWith authSecret: Data, encryptionHeader: String, cryptoKeyHeader: String) throws -> Data {
        var plaintextLen = ece_aesgcm_plaintext_max_length(ciphertext.count) + 1
        var plaintext = [UInt8](repeating: 0, count: plaintextLen)

        let err = ece_webpush_aesgcm_decrypt(
                rawRecvPrivKey.getBytes(), rawRecvPrivKey.count,
                authSecret.getBytes(), authSecret.count,
                cryptoKeyHeader, encryptionHeader,
                ciphertext.getBytes(), ciphertext.count,
                &plaintext, &plaintextLen)

        if err != ECE_OK {
            throw PushCryptoError.decryptionError(errCode: err)
        }

        return Data(bytes: plaintext, count: plaintextLen)
    }
}

extension PushCrypto {
    func generateKeys() throws -> PushKeys {
        // The subscription private key. This key should never be sent to the app
        // server. It should be persisted with the endpoint and auth secret, and used
        // to decrypt all messages sent to the subscription.
        let privateKeyLength = Int(ECE_WEBPUSH_PRIVATE_KEY_LENGTH)
        var rawRecvPrivKey = [UInt8](repeating: 0, count: privateKeyLength)

        // The subscription public key. This key should be sent to the app server,
        // and used to encrypt messages. The Push DOM API exposes the public key via
        // `pushSubscription.getKey("p256dh")`.
        let publicKeyLength = Int(ECE_WEBPUSH_PUBLIC_KEY_LENGTH)
        var rawRecvPubKey = [UInt8](repeating: 0, count: publicKeyLength)

        // The shared auth secret. This secret should be persisted with the
        // subscription information, and sent to the app server. The DOM API exposes
        // the auth secret via `pushSubscription.getKey("auth")`.
        let authSecretLength = Int(ECE_WEBPUSH_AUTH_SECRET_LENGTH)
        var authSecret = [UInt8](repeating: 0, count: authSecretLength)

        let err = ece_webpush_generate_keys(
            &rawRecvPrivKey, privateKeyLength,
            &rawRecvPubKey, publicKeyLength,
            &authSecret, authSecretLength)

        if err != ECE_OK {
            throw PushCryptoError.keyGenerationError(errCode: err)
        }

        let privKey = Data(bytes: rawRecvPrivKey, count: privateKeyLength).base64urlSafeEncodedString
        let pubKey =  Data(bytes: rawRecvPubKey, count: publicKeyLength).base64urlSafeEncodedString
        let authKey = Data(bytes: authSecret, count: authSecretLength).base64urlSafeEncodedString

        return PushKeys(p256dhPrivateKey: privKey, p256dhPublicKey: pubKey, auth: authKey)
    }
}

struct PushKeys {
    let p256dhPrivateKey: String
    let p256dhPublicKey: String
    let auth: String
}

enum PushCryptoError: Error {
    case base64DecodeError
    case decryptionError(errCode: Int32)
    case encryptionError(errCode: Int32)
    case keyGenerationError(errCode: Int32)
    case utf8EncodingError
}

extension String {
    /// Returns a base64 url safe decoding of the given string.
    /// The string is allowed to be padded
    /// What is padding?: http://stackoverflow.com/a/26632221
    var base64urlSafeDecodedData: Data? {
        // We call this method twice: once with the last two args as nil, 0 – this gets us the length
        // of the decoded string.
        let length = ece_base64url_decode(self, self.characters.count, ECE_BASE64URL_REJECT_PADDING, nil, 0)
        guard length > 0 else {
            return nil
        }

        // The second time, we actually decode, and copy it into a made to measure byte array.
        var bytes = [UInt8](repeating: 0, count: length)
        let checkLength = ece_base64url_decode(self, self.characters.count, ECE_BASE64URL_REJECT_PADDING, &bytes, length)
        guard checkLength == length else {
            return nil
        }

        return Data(bytes: bytes, count: length)
    }
}

extension Data {
    /// Returns a base64 url safe encoding of the given data.
    var base64urlSafeEncodedString: String {
        return self.base64EncodedString
            .replacingOccurrences(of: "+", with: "-", options: .literal)
            .replacingOccurrences(of: "/", with: "_", options: .literal)
            .replacingOccurrences(of: "=", with: "", options: [.anchored, .backwards])
    }
}
