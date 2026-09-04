// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

extension Error {
    /// A telemetry-safe descriptor for an arbitrary error, built from the bridged `NSError` domain and code.
    public var telemetryDescription: String {
        let nsError = self as NSError
        return "domain: \(nsError.domain), code: \(nsError.code)"
    }
}
