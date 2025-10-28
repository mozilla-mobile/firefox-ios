// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

extension UIFont {
    private static let familyBrandFontName = "FoundersGroteskCond-SmBd"

    public static func ecosiaFamilyBrand(size: CGFloat) -> UIFont {
        return UIFont(name: familyBrandFontName, size: size) ?? systemFont(ofSize: size, weight: .semibold)
    }
}
