// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

public struct DefaultDynamicFontHelper {
    public static func preferredFont(withTextStyle textStyle: UIFont.TextStyle,
                                     size: CGFloat,
                                     weight: UIFont.Weight? = nil,
                                     symbolicTraits: UIFontDescriptor.SymbolicTraits? = nil) -> UIFont {
        let fontMetrics = UIFontMetrics(forTextStyle: textStyle)
        var fontDescriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: textStyle)

        if let symbolicTraits = symbolicTraits, let descriptor = fontDescriptor.withSymbolicTraits(symbolicTraits) {
            fontDescriptor = descriptor
        }

        var font: UIFont
        if let weight = weight {
            font = UIFont.systemFont(ofSize: size, weight: weight)
        } else {
            font = UIFont(descriptor: fontDescriptor, size: size)
        }

        return fontMetrics.scaledFont(for: font)
    }

    public static func preferredBoldFont(withTextStyle textStyle: UIFont.TextStyle, size: CGFloat) -> UIFont {
        return preferredFont(withTextStyle: textStyle, size: size, weight: .bold)
    }
}
