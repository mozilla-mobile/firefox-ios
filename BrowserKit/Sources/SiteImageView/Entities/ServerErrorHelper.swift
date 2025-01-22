// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

struct ServerErrorHelper {
    /// Extracts whether the given error is a server-side error (5xx status code).
    /// - Parameter error: The error to be checked.
    /// - Returns: A boolean indicating if the error is a server error (5xx).
    static func extractServerError(_ error: Error) -> Bool {
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .timedOut, .networkConnectionLost:
                return false
            default:
                break
            }
        }

        if let httpError = error as? HTTPURLResponse {
            return httpError.statusCode >= 500 && httpError.statusCode < 600
        }

        return false
    }
}
