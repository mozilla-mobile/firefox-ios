// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import MozillaAppServices

/// Failure surface returned by `WorldCupAPIClientProtocol.load*`. Maps the
/// FFI `MerinoWorldCupApiError` (plus any decode / unexpected error) into a
/// small Swift-side enum so UI code can switch on the failure type without
/// importing `MozillaAppServices`.
enum WorldCupLoadError: Error, Equatable {
    /// Transport-level failure (no connectivity, DNS, TLS, etc.). UI should
    /// hint the user to check connectivity.
    case network(reason: String)
    /// Anything else — HTTP error, server validation, decode failure,
    /// unexpected error. UI shows a generic "something went wrong" message.
    case other(code: UInt16?, reason: String)

    static func from(_ error: Error) -> WorldCupLoadError {
        if let api = error as? MerinoWorldCupApiError {
            switch api {
            case .Network(let reason):
                return .network(reason: reason)
            case .Other(let code, let reason):
                return .other(code: code, reason: reason)
            }
        }
        return .other(code: nil, reason: String(describing: error))
    }
}
