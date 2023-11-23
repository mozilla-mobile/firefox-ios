// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

public struct HeroImageViewColor {
    let faviconTintColor: UIColor
    let faviconBackgroundColor: UIColor
    let faviconBorderColor: UIColor

    public init(faviconTintColor: UIColor,
                faviconBackgroundColor: UIColor,
                faviconBorderColor: UIColor) {
        self.faviconTintColor = faviconTintColor
        self.faviconBackgroundColor = faviconBackgroundColor
        self.faviconBorderColor = faviconBorderColor
    }
}
