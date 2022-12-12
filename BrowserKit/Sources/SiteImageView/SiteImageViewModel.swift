// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import UIKit

public struct SiteImageViewModel {
    let siteURL: URL
    let type: SiteImageType

    let generalCornerRadius: CGFloat
    let faviconCornerRadius: CGFloat
    let faviconBorderWidth: CGFloat
    let heroImageSize: CGSize
    let fallbackFaviconSize: CGSize
}
