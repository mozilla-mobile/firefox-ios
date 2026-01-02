// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// All error types for JWT encoding and decoding flows.
public enum JWTError: Error, Equatable {
    case jsonEncoding
    case invalidFormat
    case base64Decoding
    case jsonDecoding
    case invalidSignature
}
