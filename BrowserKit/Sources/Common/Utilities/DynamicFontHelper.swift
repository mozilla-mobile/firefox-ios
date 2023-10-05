// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

public protocol DynamicFontHelper {
    /// Returns a font that will dynamically scale with dynamic text
    /// - Parameters:
    ///   - textStyle: The desired textStyle for the font
    ///   - size: The size of the font
    /// - Returns: The UIFont with the specified font size and style
    static func preferredFont(withTextStyle textStyle: UIFont.TextStyle,
                              size: CGFloat,
                              weight: UIFont.Weight?,
                              symbolicTraits: UIFontDescriptor.SymbolicTraits?
    ) -> UIFont

    /// Return a bold font that will dynamically scale up to a certain size
    /// - Parameters:
    ///   - textStyle: The desired textStyle for the font
    ///   - size: The size of the font
    /// - Returns: The UIFont with the specified font size, style and bold weight
    static func preferredBoldFont(withTextStyle textStyle: UIFont.TextStyle,
                                  size: CGFloat
    ) -> UIFont
}

public extension DynamicFontHelper {
    static func preferredFont(withTextStyle textStyle: UIFont.TextStyle,
                              size: CGFloat,
                              weight: UIFont.Weight? = nil,
                              symbolicTraits: UIFontDescriptor.SymbolicTraits? = nil
    ) -> UIFont {
        preferredFont(withTextStyle: textStyle, size: size, weight: weight, symbolicTraits: symbolicTraits)
    }
}

public struct DefaultDynamicFontHelper: DynamicFontHelper {
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
