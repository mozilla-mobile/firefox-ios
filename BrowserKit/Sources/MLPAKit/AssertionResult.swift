// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// The raw cryptographic output of an App Attest assertion,
/// before any protocol-specific encoding (e.g. JWT).
/// Callers (such as `RequestAuthProtocol` conformers) use these
/// primitives to build whatever auth format the server expects.
public struct AssertionResult {
    public let keyId: String
    public let assertion: Data
    public let challenge: String
    public let payload: Data
}
