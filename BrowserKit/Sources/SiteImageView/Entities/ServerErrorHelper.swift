// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

struct ServerErrorHelper {
    /// Extracts whether the given error is related to user connectivity (not a server-side error).
    /// - Parameter error: The error to be checked.
    /// - Returns: A boolean indicating if the error is a connectivity error (e.g., no internet connection).
    static func isClientError(_ error: Error) -> Bool {
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .timedOut, .networkConnectionLost:
                return true
            default:
                break
            }
        }

        return false
    }
}
