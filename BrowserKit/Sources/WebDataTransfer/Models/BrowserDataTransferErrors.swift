// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

enum BrowserDataTransferErrors {
    /// BrowserKit only reports broad error codes, so framework errors map to `.unknown`.
    static func failureReason(for error: Error) -> BrowserTransferResult.FailureReason? {
        // Cancellation is user invoked, we do not want to show an error in that case.
        return error is CancellationError ? nil : .unknown
    }
}
