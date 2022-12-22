// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import SiteImageView

struct HomepageFaviconImageViewModel: FaviconImageViewModel {
    var urlStringRequest: String
    var type: SiteImageView.SiteImageType = .favicon
    var faviconCornerRadius: CGFloat = HomepageViewModel.UX.generalIconCornerRadius
    var usesIndirectDomain = false
}
