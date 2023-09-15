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

    init(price: [String], quality: [String], competitiveness: [String]) {
        self.price = price
        self.quality = quality
        self.competitiveness = competitiveness
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        price = try container.decodeIfPresent([String].self, forKey: .price) ?? []
        quality = try container.decodeIfPresent([String].self, forKey: .quality) ?? []
        competitiveness = try container.decodeIfPresent([String].self, forKey: .competitiveness) ?? []
    }
}
