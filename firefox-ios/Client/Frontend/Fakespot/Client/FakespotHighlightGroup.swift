// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common

private typealias A11yId = AccessibilityIdentifiers.Shopping.HighlightsCard

enum FakespotHighlightType: String {
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
        case .price: return StandardImageIdentifiers.Large.price
        case .quality: return StandardImageIdentifiers.Large.quality
        case .competitiveness: return StandardImageIdentifiers.Large.competitiveness
        case .shipping: return StandardImageIdentifiers.Large.shipping
        case .packaging: return StandardImageIdentifiers.Large.packaging
        }
    }

    var titleA11yId: String {
        switch self {
        case .price: return A11yId.groupPriceTitle
        case .quality: return A11yId.groupQualityTitle
        case .competitiveness: return A11yId.groupCompetitivenessTitle
        case .shipping: return A11yId.groupShippingTitle
        case .packaging: return A11yId.groupPackagingTitle
        }
    }

    var iconA11yId: String {
        switch self {
        case .price: return A11yId.groupPriceIcon
        case .quality: return A11yId.groupQualityIcon
        case .competitiveness: return A11yId.groupCompetitivenessIcon
        case .shipping: return A11yId.groupShippingIcon
        case .packaging: return A11yId.groupPackagingIcon
        }
    }

    var highlightsA11yId: String {
        switch self {
        case .price: return A11yId.groupPriceHighlightsLabel
        case .quality: return A11yId.groupQualityHighlightsLabel
        case .competitiveness: return A11yId.groupCompetitivenessHighlightsLabel
        case .shipping: return A11yId.groupShippingHighlightsLabel
        case .packaging: return A11yId.groupPackagingHighlightsLabel
        }
    }
}

struct FakespotHighlightGroup: Equatable {
    let type: FakespotHighlightType
    let reviews: [String]
}
