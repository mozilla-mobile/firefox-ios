// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common
import Shared

/// Encodes a payload into a JSON Web Token (JWT).
///
/// The encoder uses a pluggable `JWTAlgorithmStrategy` to:
/// - Set the `alg` header value
/// - Sign the `<header>.<payload>` string
///
/// The resulting token has the structure:
///
/// ```text
/// base64url(header).base64url(payload).base64url(signature)
/// ```
public final class JWTEncoder {
    /// The algorithm strategy used to sign the token.
    private let algorithm: JWTAlgorithm

    /// Creates a new encoder with the given algorithm strategy.
    public init(algorithm: JWTAlgorithm) {
        self.algorithm = algorithm
    }

    /// Encodes the given payload into a JWT string.
    public func encode(payload: [String: Any]) throws -> String {
        let header = JWTHeader(algorithm: algorithm)

        guard let encodedHeader = try? header.encoded(),
              JSONSerialization.isValidJSONObject(payload),
              let payloadData = try? JSONSerialization.data(withJSONObject: payload, options: []) else {
            throw JWTError.jsonEncoding
        }

        let encodedPayload = Bytes.base64urlSafeEncodeData(payloadData)

        let signingInput = "\(encodedHeader).\(encodedPayload)"
        let strategy = algorithm.makeStrategy()
        let signature = try strategy.sign(message: signingInput)
        return "\(signingInput).\(signature)"
    }
}
