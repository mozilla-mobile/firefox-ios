// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import SiteImageView

struct HomepageHeroImageViewModel: HeroImageViewModel {
    let urlStringRequest: String
    let type: SiteImageView.SiteImageType = .heroImage
    let generalCornerRadius: CGFloat = HomepageViewModel.UX.generalCornerRadius
    let faviconCornerRadius: CGFloat = HomepageViewModel.UX.generalCornerRadius
    let faviconBorderWidth: CGFloat = HomepageViewModel.UX.generalBorderWidth
    let heroImageSize: CGSize
    let fallbackFaviconSize: CGSize = HomepageViewModel.UX.fallbackFaviconSize
}
