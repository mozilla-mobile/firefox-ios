// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

struct ProductAnalyzeResponse: Decodable {
    /// Enumeration representing different analysis statuses.
    enum AnalysisStatus: String, Decodable {
        case pending = "pending"
        case inProgress = "in_progress"
        case completed = "completed"
        case notAnalyzable = "not_analyzable"
        case notFound = "not_found"
        case unprocessable = "unprocessable"
    }

    let status: AnalysisStatus
}
