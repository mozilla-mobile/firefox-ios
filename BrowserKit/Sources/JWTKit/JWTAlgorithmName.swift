// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Enum to keep track of JWT algorithm identifiers.
///
/// These correspond to the `alg` field inside the JWT header.
public enum JWTAlgorithmName: String, Codable, Equatable {
    case none = "none"
    case hs256 = "HS256"
}
