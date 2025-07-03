// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import UIKit
import SwiftUI

// This class should only be instantiated in FXFontStyles
public struct TextStyling {
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
        return DefaultDynamicFontHelper.preferredSwiftUIFont(withTextStyle: textStyle,
                                                             size: size,
                                                             sizeCap: sizeCap,
                                                             weight: weight.toSwiftUIWeight())
    }

    public func systemSwiftUIFont() -> Font {
        return Font.system(size: size, weight: weight.toSwiftUIWeight())
    }

    public func monospacedSwiftUIFont() -> Font {
        return DefaultDynamicFontHelper.preferredSwiftUIFont(withTextStyle: textStyle,
                                                             size: size,
                                                             weight: weight.toSwiftUIWeight(),
                                                             design: .monospaced)
    }
}

// MARK: - UIFont.Weight to SwiftUI Font.Weight Extension
extension UIFont.Weight {
    func toSwiftUIWeight() -> Font.Weight {
        switch self {
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
