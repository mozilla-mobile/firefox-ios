// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

public struct FaviconImageViewModel {
    var siteURLString: String?
    var siteResource: SiteResource?
    var faviconCornerRadius: CGFloat

    public init(siteURLString: String? = nil,
                siteResource: SiteResource? = nil,
                faviconCornerRadius: CGFloat = 4) {
        self.siteURLString = siteURLString
        self.siteResource = siteResource
        self.faviconCornerRadius = faviconCornerRadius
    }
}
