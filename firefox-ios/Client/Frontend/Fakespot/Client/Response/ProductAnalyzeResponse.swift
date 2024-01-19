// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Enumeration representing the various analysis statuses for a product.
enum AnalysisStatus: String, Decodable {
    /// The analysis is pending and has not yet started.
    case pending = "pending"

    /// The analysis job is in progress, indicating it is currently being processed.
    case inProgress = "in_progress"

    /// The analysis has been completed successfully.
    case completed = "completed"

    /// The product cannot be analyzed due to eligibility constraints.
    case notAnalyzable = "not_analyzable"

    /// The current analysis status with provided parameters is not found.
    case notFound = "not_found"

    /// The product cannot be analyzed with the provided data, often due to issues like
    /// an incorrect website or product ID.
    case unprocessable = "unprocessable"

    /// The analysis is stale, returned if the analysis is not finished within 3 minutes.
    case stale = "stale"

    /// The product cannot be analyzed due to an insufficient number of reviews.
    case notEnoughReviews = "not_enough_reviews"

    /// The system does not support analyses for the provided product.
    case pageNotSupported = "page_not_supported"

    var isAnalyzing: Bool {
        switch self {
        case .pending, .inProgress:
            return true
        default:
            return false
        }
    }
}

struct ProductAnalyzeResponse: Decodable {
    let status: AnalysisStatus
}

struct ProductAnalysisStatusResponse: Decodable {
    let status: AnalysisStatus
    let progress: Double
}
