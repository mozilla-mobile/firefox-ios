// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Represents the signing algorithm used when encoding a JWT.
///
/// This enum provides a high-level API for selecting the desired JWT algorithm.
/// It maps directly to the `alg` field inside the JWT header and determines
/// how the `<header>.<payload>` string is signed.
///
/// Only a subset of JWA (JSON Web Algorithms) is implemented here.
/// For the full registry of supported JWT algorithms, see:
///
///   https://www.iana.org/assignments/jose/jose.xhtml#web-signature-encryption-algorithms
///
/// NOTE: Additional algorithms (e.g., RS256, ES256) can be added as new cases
/// following the same pattern by providing their `name` and an implementation of `makeStrategy()`.
/// For the summarizer, we only need `none` and `HS256` for now.
public enum JWTAlgorithm {
    case none
    case hs256(secret: String)

    var name: String {
        switch self {
        case .none: return "none"
        case .hs256: return "HS256"
        }
    }

    /// Creates the concrete signing strategy used by `JWTEncoder`.
    func makeStrategy() -> JWTAlgorithmStrategy {
        switch self {
        case .none:
            return JWTNoneAlgorithm()
        case let .hs256(secret):
            return JWTHS256Algorithm(secret: secret)
        }
    }
}
