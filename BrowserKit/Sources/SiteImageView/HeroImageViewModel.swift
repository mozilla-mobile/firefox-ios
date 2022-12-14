// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import UIKit

public struct HeroImageViewModel {
    let siteURL: URL
    let type: SiteImageType
    let generalCornerRadius: CGFloat
    let faviconCornerRadius: CGFloat
    let faviconBorderWidth: CGFloat
    let heroImageSize: CGSize
    let fallbackFaviconSize: CGSize

    public init(siteURL: URL,
                generalCornerRadius: CGFloat,
                faviconCornerRadius: CGFloat,
                faviconBorderWidth: CGFloat,
                heroImageSize: CGSize,
                fallbackFaviconSize: CGSize) {
        self.type = .heroImage
        self.siteURL = siteURL
        self.generalCornerRadius = generalCornerRadius
        self.faviconCornerRadius = faviconCornerRadius
        self.faviconBorderWidth = faviconBorderWidth
        self.heroImageSize = heroImageSize
        self.fallbackFaviconSize = fallbackFaviconSize
    }
}
