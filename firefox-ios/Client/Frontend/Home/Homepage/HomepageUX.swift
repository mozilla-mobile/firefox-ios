// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

struct HomepageUX {
    // Shadow
    static let shadowRadius: CGFloat = 4
    static let shadowOffset = CGSize(width: 0, height: 2)
    static let shadowOpacity: Float = 1 // shadow opacity set to 0.16 through shadowDefault themed color

    // General
    static let generalCornerRadius: CGFloat = 8
    static let generalBorderWidth: CGFloat = 0.5

    // Top sites
    static let topSiteIconSize = CGSize(width: 36, height: 36)
    static let imageBackgroundSize = CGSize(width: 60, height: 60)
    static let fallbackFaviconSize = CGSize(width: 36, height: 36)
}
