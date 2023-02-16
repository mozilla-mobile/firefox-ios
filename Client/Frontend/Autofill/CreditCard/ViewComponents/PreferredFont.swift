// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI

struct PreferredFontStyle: ViewModifier {
    var size: CGFloat
    var weight: Font.Weight?

    private var font: Font {
        var font = Font.custom("SF Pro", size: size)

        if let weight = weight {
            font = font.weight(weight)
        }
        return font
    }

    func body(content: Content) -> some View {
        content
            .font(font)
    }
}

extension View {
    func preferredBodyFont(size: CGFloat, weight: Font.Weight? = nil) -> some View {
        self.modifier(PreferredFontStyle(size: size, weight: weight))
    }
}
