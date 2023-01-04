// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import UIKit

public struct FaviconImageViewModel {
    var urlStringRequest: String
    var faviconCornerRadius: CGFloat
    var usesIndirectDomain: Bool

    public init(urlStringRequest: String,
                faviconCornerRadius: CGFloat = 4,
                usesIndirectDomain: Bool = false) {
        self.urlStringRequest = urlStringRequest
        self.faviconCornerRadius = faviconCornerRadius
        self.usesIndirectDomain = usesIndirectDomain
    }
}
