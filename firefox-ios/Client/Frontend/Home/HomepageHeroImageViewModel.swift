// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import SiteImageView

struct HomepageHeroImageViewModel: HeroImageViewModel {
    struct UX {
        static let generalCornerRadius: CGFloat = 8
        static let generalBorderWidth: CGFloat = 0.5
        static let fallbackFaviconSize = CGSize(width: 36, height: 36)
    }

    let urlStringRequest: String
    let type: SiteImageView.SiteImageType
    let generalCornerRadius: CGFloat
    let faviconCornerRadius: CGFloat
    let faviconBorderWidth: CGFloat
    let heroImageSize: CGSize
    let fallbackFaviconSize: CGSize

    init(
        urlStringRequest: String,
        type: SiteImageView.SiteImageType = .heroImage,
        generalCornerRadius: CGFloat = UX.generalCornerRadius,
        faviconCornerRadius: CGFloat = UX.generalCornerRadius,
        faviconBorderWidth: CGFloat = UX.generalBorderWidth,
        heroImageSize: CGSize,
        fallbackFaviconSize: CGSize = UX.fallbackFaviconSize
    ) {
        self.urlStringRequest = urlStringRequest
        self.type = type
        self.generalCornerRadius = generalCornerRadius
        self.faviconCornerRadius = faviconCornerRadius
        self.faviconBorderWidth = faviconBorderWidth
        self.heroImageSize = heroImageSize
        self.fallbackFaviconSize = fallbackFaviconSize
    }
}
