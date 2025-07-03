// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import SwiftUI

public protocol DynamicFontHelper {
    /// Returns a font that will dynamically scale with dynamic text
    /// - Parameters:
    ///   - textStyle: The desired textStyle for the font
    ///   - size: The size of the font
    /// - Returns: The UIFont with the specified font size and style
    static func preferredFont(withTextStyle textStyle: UIFont.TextStyle,
                              size: CGFloat,
                              sizeCap: CGFloat?,
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
                              sizeCap: CGFloat? = nil,
                              weight: UIFont.Weight? = nil,
                              symbolicTraits: UIFontDescriptor.SymbolicTraits? = nil
    ) -> UIFont {
        preferredFont(withTextStyle: textStyle,
                      size: size,
                      sizeCap: sizeCap,
                      weight: weight,
                      symbolicTraits: symbolicTraits)
    }
}

public struct DefaultDynamicFontHelper: DynamicFontHelper {
    public static func preferredFont(withTextStyle textStyle: UIFont.TextStyle,
                                     size: CGFloat,
                                     sizeCap: CGFloat? = nil,
                                     weight: UIFont.Weight? = nil,
                                     symbolicTraits: UIFontDescriptor.SymbolicTraits? = nil) -> UIFont {
        let fontMetrics = UIFontMetrics(forTextStyle: textStyle)
        var fontDescriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: textStyle)

        if let symbolicTraits = symbolicTraits, let descriptor = fontDescriptor.withSymbolicTraits(symbolicTraits) {
            fontDescriptor = descriptor
        }

        let font = fontForWeight(descriptor: fontDescriptor,
                                 size: size,
                                 weight: weight)
        let scaledFont = fontMetrics.scaledFont(for: font)

        if let sizeCap {
            if scaledFont.pointSize > sizeCap {
                return fontForWeight(descriptor: fontDescriptor,
                                     size: sizeCap,
                                     weight: weight)
            }
        }

        return scaledFont
    }

    static func fontForWeight(descriptor: UIFontDescriptor, size: CGFloat, weight: UIFont.Weight?) -> UIFont {
        if let weight = weight {
            return UIFont.systemFont(ofSize: size, weight: weight)
        } else {
            return UIFont(descriptor: descriptor, size: size)
        }
    }

    public static func preferredBoldFont(withTextStyle textStyle: UIFont.TextStyle, size: CGFloat) -> UIFont {
        return preferredFont(withTextStyle: textStyle, size: size, weight: .bold)
    }

    // MARK: - SwiftUI Font Methods

    public static func preferredSwiftUIFont(withTextStyle textStyle: UIFont.TextStyle,
                                            size: CGFloat,
                                            sizeCap: CGFloat? = nil,
                                            weight: Font.Weight? = nil,
                                            design: Font.Design = .default) -> Font {
        let swiftUITextStyle = textStyle.toSwiftUITextStyle()
        var font = Font.system(swiftUITextStyle, design: design)

        if let weight = weight {
            font = font.weight(weight)
        }

        // Apply size cap if specified
        if let sizeCap = sizeCap {
            // Create a custom font that respects the size cap
            return Font.custom("", size: min(size, sizeCap), relativeTo: swiftUITextStyle)
        }

        return font
    }

    public static func preferredBoldSwiftUIFont(withTextStyle textStyle: UIFont.TextStyle,
                                                size: CGFloat,
                                                design: Font.Design = .default) -> Font {
        return preferredSwiftUIFont(withTextStyle: textStyle,
                                    size: size,
                                    weight: .bold,
                                    design: design)
    }
}

// MARK: - UIFont.TextStyle to SwiftUI Font.TextStyle Extension
extension UIFont.TextStyle {
    func toSwiftUITextStyle() -> Font.TextStyle {
        switch self {
        case .largeTitle: return .largeTitle
        case .title1: return .title
        case .title2: return .title2
        case .title3: return .title3
        case .headline: return .headline
        case .subheadline: return .subheadline
        case .body: return .body
        case .callout: return .callout
        case .footnote: return .footnote
        case .caption1: return .caption
        case .caption2: return .caption2
        default: return .body
        }
    }
}
