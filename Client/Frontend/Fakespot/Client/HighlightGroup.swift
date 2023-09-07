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

    var titleA11yId: String {
        switch self {
        case .price: return AccessibilityIdentifiers.Shopping.HighlightsCard.groupPriceTitle
        case .quality: return AccessibilityIdentifiers.Shopping.HighlightsCard.groupQualityTitle
        case .competitiveness: return AccessibilityIdentifiers.Shopping.HighlightsCard.groupCompetitivenessTitle
        case .shipping: return AccessibilityIdentifiers.Shopping.HighlightsCard.groupShippingTitle
        case .packaging: return AccessibilityIdentifiers.Shopping.HighlightsCard.groupPackagingTitle
        }
    }

    var iconA11yId: String {
        switch self {
        case .price: return AccessibilityIdentifiers.Shopping.HighlightsCard.groupPriceIcon
        case .quality: return AccessibilityIdentifiers.Shopping.HighlightsCard.groupQualityIcon
        case .competitiveness: return AccessibilityIdentifiers.Shopping.HighlightsCard.groupCompetitivenessIcon
        case .shipping: return AccessibilityIdentifiers.Shopping.HighlightsCard.groupShippingIcon
        case .packaging: return AccessibilityIdentifiers.Shopping.HighlightsCard.groupPackagingIcon
        }
    }

    var highlightsA11yId: String {
        switch self {
        case .price: return AccessibilityIdentifiers.Shopping.HighlightsCard.groupPriceHighlightsLabel
        case .quality: return AccessibilityIdentifiers.Shopping.HighlightsCard.groupQualityHighlightsLabel
        case .competitiveness: return AccessibilityIdentifiers.Shopping.HighlightsCard.groupCompetitivenessHighlightsLabel
        case .shipping: return AccessibilityIdentifiers.Shopping.HighlightsCard.groupShippingHighlightsLabel
        case .packaging: return AccessibilityIdentifiers.Shopping.HighlightsCard.groupPackagingHighlightsLabel
        }
    }
}

struct HighlightGroup {
    let type: HighlightType
    let reviews: [String]
}
