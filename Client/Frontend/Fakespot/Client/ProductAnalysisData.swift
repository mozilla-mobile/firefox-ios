// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

struct ProductAnalysisData: Codable {
    let productId: String?
    let grade: ReliabilityGrade?
    let adjustedRating: Double?
    let needsAnalysis: Bool?
    let analysisUrl: URL?
    let highlights: Highlights?
    let pageNotSupported: Bool?

    private enum CodingKeys: String, CodingKey {
        case productId = "product_id"
        case grade
        case adjustedRating = "adjusted_rating"
        case needsAnalysis = "needs_analysis"
        case analysisUrl = "analysis_url"
        case highlights
        case pageNotSupported = "page_not_supported"
    }

    var notAnalyzedCardVisible: Bool {
        productId == nil && needsAnalysis == true
    }

    var cannotBeAnalyzedCardVisible: Bool {
        needsAnalysis == false && pageNotSupported == true
    }

    var notEnoughReviewsCardVisible: Bool {
        (grade == nil || adjustedRating == nil) && needsAnalysis == true
    }
}

struct Highlights: Codable {
    let price: [String]
    let quality: [String]
    let competitiveness: [String]
    let shipping: [String]
    let packaging: [String]

    private enum CodingKeys: String, CodingKey {
        case price
        case quality
        case competitiveness
        case shipping
        case packaging = "packaging/appearance"
    }

    init(price: [String],
         quality: [String],
         competitiveness: [String],
         shipping: [String],
         packaging: [String]) {
        self.price = price
        self.quality = quality
        self.competitiveness = competitiveness
        self.shipping = shipping
        self.packaging = packaging
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        price = try container.decodeIfPresent([String].self, forKey: .price) ?? []
        quality = try container.decodeIfPresent([String].self, forKey: .quality) ?? []
        competitiveness = try container.decodeIfPresent([String].self, forKey: .competitiveness) ?? []
        shipping = try container.decodeIfPresent([String].self, forKey: .shipping) ?? []
        packaging = try container.decodeIfPresent([String].self, forKey: .packaging) ?? []
    }

    var items: [FakespotHighlightGroup] {
        var items = [FakespotHighlightGroup]()
        items.append(FakespotHighlightGroup(type: .price, reviews: price))
        items.append(FakespotHighlightGroup(type: .quality, reviews: quality))
        items.append(FakespotHighlightGroup(type: .shipping, reviews: shipping))
        items.append(FakespotHighlightGroup(type: .competitiveness, reviews: competitiveness))
        items.append(FakespotHighlightGroup(type: .packaging, reviews: packaging))
        return items.compactMap { group in group.reviews.isEmpty ? nil : group }
    }
}
