// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

struct ProductAnalysisData: Codable {
    let productId: String?
    let grade: String?
    let adjustedRating: Double?
    let needsAnalysis: Bool?
    let analysisUrl: URL?
    let highlights: Highlights?

    private enum CodingKeys: String, CodingKey {
        case productId = "product_id"
        case grade
        case adjustedRating = "adjusted_rating"
        case needsAnalysis = "needs_analysis"
        case analysisUrl = "analysis_url"
        case highlights
    }
}

struct Highlights: Codable {
    let price: [String]
    let quality: [String]
    let competitiveness: [String]
}
