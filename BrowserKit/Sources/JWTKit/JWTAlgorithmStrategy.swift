// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// A strategy that defines how a JWT is signed and verified.
///
/// Conforming types encapsulate a specific signing algorithm
/// (e.g. `none`, `HS256`) and are used by `JWTEncoder` and `JWTDecoder`
/// to:
///  - provide the `alg` header value
///  - sign the `<header>.<payload>` input
///  - verify a given signature for that same input
/// 
/// For more context on how JWTs work, see: https://jwt.io/introduction
public protocol JWTAlgorithmStrategy {
    /// Produces a Base64URL-encoded signature for the given message.
    func sign(message: String) throws -> String
    /// Verifies the Base64URL-encoded signature for the given message.
    func verify(message: String, hasSignature signature: String) throws
}
