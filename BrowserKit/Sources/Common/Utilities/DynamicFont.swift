// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI

public struct DynamicFont: Sendable {
    let textStyle: Font.TextStyle
    let size: CGFloat
    let sizeCap: CGFloat?
    let weight: Font.Weight?
    let design: Font.Design

    init(textStyle: Font.TextStyle,
         size: CGFloat,
         sizeCap: CGFloat? = nil,
         weight: Font.Weight? = nil,
         design: Font.Design = .default) {
        self.textStyle = textStyle
        self.size = size
        self.sizeCap = sizeCap
        self.weight = weight
        self.design = design
    }
}

extension View {
    public func font(_ dynamicFont: DynamicFont) -> some View {
        modifier(DynamicFontModifier(dynamicFont: dynamicFont))
    }
}

private struct DynamicFontModifier: ViewModifier {
    @Environment(\.sizeCategory) var sizeCategory
    let dynamicFont: DynamicFont

    func body(content: Content) -> some View {
        content.font(calculateFont())
    }

    private func calculateFont() -> Font {
        let uiTextStyle = TextStyling.toUIFontTextStyle(dynamicFont.textStyle)
        let uiWeight = dynamicFont.weight.map { TextStyling.toUIFontWeight($0) }

        // UIFontMetrics.scaledFont automatically uses the current content size category
        // from UIApplication.shared.preferredContentSizeCategory
        let scaledFont = DefaultDynamicFontHelper.preferredFont(
            withTextStyle: uiTextStyle,
            size: dynamicFont.size,
            sizeCap: dynamicFont.sizeCap,
            weight: uiWeight
        )

        var font = Font.system(size: scaledFont.pointSize, design: dynamicFont.design)
        if let weight = dynamicFont.weight {
            font = font.weight(weight)
        }

        return font
    }
}
