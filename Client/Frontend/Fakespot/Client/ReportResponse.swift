// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// A struct representing a response from a report-related operation.
struct ReportResponse: Decodable {
    /// An enumeration of possible messages in the response.
    enum Message: String, Decodable {
        /// Indicates that a report has been successfully created.
        case reportCreated = "report created"

        /// Indicates that the item has already been reported.
        case alreadyReported = "already reported"

        /// Indicates that the item could not be deleted.
        case notDeleted = "not deleted"
    }

    /// The message associated with the response, indicating the result of the report operation.
    let message: Message
}
