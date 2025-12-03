// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import CryptoKit
import Common

/// A JWT algorithm strategy implementing HMAC-SHA256 (`HS256`).
///
/// This is a symmetric signing algorithm: the same shared secret is used for both signing and verifying tokens.
public struct JWTHS256Algorithm: JWTAlgorithmStrategy {
    /// The shared secret key used for HMAC-SHA256 signing.
    private let secret: String

    public init(secret: String) {
        self.secret = secret
    }

    /// Computes a Base64URL-encoded HMAC-SHA256 signature for a string.
    public func sign(message: String) throws -> String {
        let key = SymmetricKey(data: Data(secret.utf8))
        let mac = HMAC<SHA256>.authenticationCode(
            for: Data(message.utf8),
            using: key
        )
        return Bytes.base64urlSafeEncodeData(Data(mac))
    }

    /// Verifies that the provided signature matches the expected one.
    public func verify(message: String, hasSignature signature: String) throws {
        guard let actualSigData = Bytes.base64urlSafeDecodedData(signature) else {
            throw JWTError.base64Decoding
        }

        let key = SymmetricKey(data: Data(secret.utf8))
        let mac = HMAC<SHA256>.authenticationCode(
            for: Data(message.utf8),
            using: key
        )
        let expectedSigData = Data(mac)

        /// NOTE: The comparison below uses a normal Swift equality check, i.e. a
        /// non-constant-time comparison. This means:
        /// - It returns as soon as a mismatch is found
        /// - It may take slightly longer if more leading bytes match
        ///
        /// This behavior can theoretically leak timing information to an attacker
        /// who is able to precisely measure how long verification takes.
        ///
        /// For our use case, this is acceptable.
        /// For a detailed explanation of timing attacks, see:
        ///
        /// https://paragonie.com/blog/2015/11/preventing-timing-attacks-on-string-comparison-with-double-hmac-strategy
        guard expectedSigData == actualSigData else {
            throw JWTError.invalidSignature
        }
    }
}
