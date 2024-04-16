// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import UIKit

// This class should only be instantiated in FXFontStyles
public struct TextStyling {
    private let textStyle: UIFont.TextStyle
    private let size: CGFloat
    private let weight: UIFont.Weight
    private let symbolicTraits: UIFontDescriptor.SymbolicTraits?

    init(for textStyle: UIFont.TextStyle, size: CGFloat, weight: UIFont.Weight,
         symbolicTraits: UIFontDescriptor.SymbolicTraits? = nil) {
        self.textStyle = textStyle
        self.size = size
        self.weight = weight
        self.symbolicTraits = symbolicTraits
    }

    public func scaledFont() -> UIFont {
        return DefaultDynamicFontHelper.preferredFont(withTextStyle: textStyle, size: size, weight: weight,
                                                      symbolicTraits: symbolicTraits)
    }

    public func systemFont() -> UIFont {
        return UIFont.systemFont(ofSize: size, weight: weight)
    }
}
