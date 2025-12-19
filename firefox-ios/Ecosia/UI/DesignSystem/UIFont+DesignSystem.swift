// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import SwiftUI

private let familyBrandFontName = "FoundersGroteskCond-SmBd"

extension UIFont {

    public static func ecosiaFamilyBrand(size: CGFloat) -> UIFont {
        return UIFont(name: familyBrandFontName, size: size) ?? systemFont(ofSize: size, weight: .semibold)
    }

    public static func ecosia(size: CGFloat, weight: UIFont.Weight = .regular) -> UIFont {
        return UIFont.systemFont(ofSize: size, weight: weight)
    }
}

extension Font {

    public static func ecosiaFamilyBrand(size: CGFloat) -> Font {
        Font.custom(familyBrandFontName, size: size)
    }

    public static func ecosia(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        Font.system(size: size, weight: weight)
    }
}
