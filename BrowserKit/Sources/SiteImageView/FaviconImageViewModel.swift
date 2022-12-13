// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import UIKit

public struct FaviconImageViewModel {
    let siteURL: URL
    let type: SiteImageType
    let faviconCornerRadius: CGFloat

    public init(siteURL: URL, faviconCornerRadius: CGFloat) {
        self.type = .favicon
        self.siteURL = siteURL
        self.faviconCornerRadius = faviconCornerRadius
    }
}
