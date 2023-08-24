// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

enum HighlightType: String {
    case price
    case quality
    case competitiveness
    case shipping
    case packaging = "packaging/appearance"

    var title: String {
        switch self {
        case .price: return .Shopping.HighlightsCardPriceTitle
        case .quality: return .Shopping.HighlightsCardQualityTitle
        case .competitiveness: return .Shopping.HighlightsCardCompetitivenessTitle
        case .shipping: return .Shopping.HighlightsCardShippingTitle
        case .packaging: return .Shopping.HighlightsCardPackagingTitle
        }
    }

    var iconName: String {
        switch self {
        case .price: return ImageIdentifiers.price
        case .quality: return ImageIdentifiers.quality
        case .competitiveness: return ImageIdentifiers.competitiveness
        case .shipping: return ImageIdentifiers.shipping
        case .packaging: return ImageIdentifiers.packaging
        }
    }
}

struct HighlightGroup {
    let type: HighlightType
    let reviews: [String]
}
