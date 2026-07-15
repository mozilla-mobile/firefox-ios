// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

enum WaybackCodes {
    static let codesForWayback: [CFNetworkErrors] = [
        .cfurlErrorTimedOut,
        .cfurlErrorCannotFindHost,
        .cfurlErrorCannotConnectToHost,
        .cfurlErrorDNSLookupFailed,
        .cfurlErrorNetworkConnectionLost,
        .cfurlErrorNotConnectedToInternet,
        .cfurlErrorResourceUnavailable
    ]

    /// Returns whether the given error code qualifies for a wayback fallback.
    static func isWaybackCode(_ code: Int) -> Bool {
        return Int32(exactly: code)
            .flatMap { CFNetworkErrors(rawValue: $0) }
            .map { codesForWayback.contains($0) } ?? false
    }
}
