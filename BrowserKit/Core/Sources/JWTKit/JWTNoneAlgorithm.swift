// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// A JWT algorithm strategy representing the `"none"` (unsecured) algorithm.
///
/// This algorithm provides NO cryptographic security. It generates empty signatures and performs no actual verification.
///
/// Only use this algorithm when:
/// - JWT is used purely as an encoding format, OR
/// - The token integrity is guaranteed through other means (e.g., TLS/HTTPS)
///
/// For secure JWT operations requiring cryptographic signatures, use `JWTHS256Algorithm` instead.
public struct JWTNoneAlgorithm: JWTAlgorithmStrategy {
    public init() {}

    /// Produces an empty signature to indicate an unsecured JWT.
    public func sign(message: String) throws -> String {
        return ""
    }

    /// Verifies that the provided signature is empty. For unsecured JWTs, any non-empty signature is invalid.
    public func verify(message: String, hasSignature signature: String) throws {
        if !signature.isEmpty {
            throw JWTError.invalidSignature
        }
    }
}
