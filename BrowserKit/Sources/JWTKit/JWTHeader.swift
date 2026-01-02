// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common
import Shared

/// Represents the JWT header section.
///
/// The spec refers to this as the `JOSE` header (JSON Object Signing and Encryption).
///
/// A JWT header contains metadata describing:
/// - the signing algorithm used (`alg`)
/// - the token type (`typ`), which is always `"JWT"`
///
/// This type provides a structured, type-safe alternative to building
/// ad-hoc `[String: Any]` dictionaries. It ensures compliance with the
/// JWT specification by always including the required fields and avoiding
/// typos like `type` instead of `typ`.
///
/// Specification reference:
///   https://datatracker.ietf.org/doc/html/rfc7519#section-5
struct JWTHeader: Encodable {
    /// The algorithm used to sign the JWT.
    /// This corresponds to the `alg` field in the JOSE header.
    /// Example values: `"none"`, `"HS256"`.
    let alg: String

    /// The token type, always `"JWT"` according to the specification.
    /// Having this hard-coded prevents incorrect or missing `typ` values.
    let typ = "JWT"

    init(algorithm: JWTAlgorithm) {
        self.alg = algorithm.name
    }

    /// Encodes the header into a Base64URL-encoded JSON string.
    /// This is the exact representation used as the first component of a JWT.
    func encoded() throws -> String {
        let data = try JSONEncoder().encode(self)
        return Bytes.base64urlSafeEncodeData(data)
    }
}
