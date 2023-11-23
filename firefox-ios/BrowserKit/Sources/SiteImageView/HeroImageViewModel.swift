// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

public protocol HeroImageViewModel {
    var urlStringRequest: String { get }
    var type: SiteImageType { get }
    var generalCornerRadius: CGFloat { get }
    var faviconCornerRadius: CGFloat { get }
    var faviconBorderWidth: CGFloat { get }
    var heroImageSize: CGSize { get }
    var fallbackFaviconSize: CGSize { get }
}

public struct DefaultHeroImageViewModel: HeroImageViewModel {
    public var urlStringRequest: String
    public var type: SiteImageType
    public var generalCornerRadius: CGFloat
    public var faviconCornerRadius: CGFloat
    public var faviconBorderWidth: CGFloat
    public var heroImageSize: CGSize
    public var fallbackFaviconSize: CGSize

    public init(urlStringRequest: String,
                generalCornerRadius: CGFloat,
                faviconCornerRadius: CGFloat,
                faviconBorderWidth: CGFloat,
                heroImageSize: CGSize,
                fallbackFaviconSize: CGSize) {
        self.type = .heroImage
        self.urlStringRequest = urlStringRequest
        self.generalCornerRadius = generalCornerRadius
        self.faviconCornerRadius = faviconCornerRadius
        self.faviconBorderWidth = faviconBorderWidth
        self.heroImageSize = heroImageSize
        self.fallbackFaviconSize = fallbackFaviconSize
    }
}
