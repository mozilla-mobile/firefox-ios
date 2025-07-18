// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import UIKit
import SwiftUI

// This class should only be instantiated in FXFontStyles
public struct TextStyling: Sendable {
    private let textStyle: UIFont.TextStyle
    private let size: CGFloat
    private let weight: UIFont.Weight

    init(for textStyle: UIFont.TextStyle, size: CGFloat, weight: UIFont.Weight) {
        self.textStyle = textStyle
        self.size = size
        self.weight = weight
    }

    public func scaledFont(sizeCap: CGFloat? = nil) -> UIFont {
        return DefaultDynamicFontHelper.preferredFont(withTextStyle: textStyle,
                                                      size: size,
                                                      sizeCap: sizeCap,
                                                      weight: weight)
    }

    public func systemFont() -> UIFont {
        return UIFont.systemFont(ofSize: size, weight: weight)
    }

    public func monospacedFont() -> UIFont {
        return DefaultDynamicFontHelper.preferredFont(withTextStyle: textStyle,
                                                      size: size,
                                                      symbolicTraits: [.traitMonoSpace])
    }

    // MARK: - SwiftUI Font Methods

    public func scaledSwiftUIFont(sizeCap: CGFloat? = nil) -> Font {
        return DefaultDynamicFontHelper.preferredSwiftUIFont(withTextStyle: toSwiftUITextStyle(textStyle),
                                                             size: size,
                                                             sizeCap: sizeCap,
                                                             weight: toSwiftUIWeight(weight))
    }

    public func systemSwiftUIFont() -> Font {
        return Font.system(size: size, weight: toSwiftUIWeight(weight))
    }

    public func monospacedSwiftUIFont() -> Font {
        return DefaultDynamicFontHelper.preferredSwiftUIFont(withTextStyle: toSwiftUITextStyle(textStyle),
                                                             size: size,
                                                             weight: toSwiftUIWeight(weight),
                                                             design: .monospaced)
    }

    private func toSwiftUITextStyle(_ style: UIFont.TextStyle) -> Font.TextStyle {
        switch style {
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

    private func toSwiftUIWeight(_ style: UIFont.Weight) -> Font.Weight {
        switch style {
        case .ultraLight: return .ultraLight
        case .thin: return .thin
        case .light: return .light
        case .regular: return .regular
        case .medium: return .medium
        case .semibold: return .semibold
        case .bold: return .bold
        case .heavy: return .heavy
        case .black: return .black
        default: return .regular
        }
    }
}
