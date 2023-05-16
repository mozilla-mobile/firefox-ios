// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI

// Switches from an HStack to VStack when the font size is one that is associated with accessibility
struct AdaptiveStack<Content: View>: View {
    let horizontalAlignment: HorizontalAlignment
    let verticalAlignment: VerticalAlignment
    let spacing: CGFloat?
    let isAccessibilityCategory: Bool
    let content: () -> Content

    init(horizontalAlignment: HorizontalAlignment = .center,
         verticalAlignment: VerticalAlignment = .center,
         spacing: CGFloat? = nil,
         isAccessibilityCategory: Bool,
         @ViewBuilder content: @escaping () -> Content) {
        self.horizontalAlignment = horizontalAlignment
        self.verticalAlignment = verticalAlignment
        self.spacing = spacing
        self.isAccessibilityCategory = isAccessibilityCategory
        self.content = content
    }

    var body: some View {
        Group {
            if isAccessibilityCategory {
                VStack(alignment: horizontalAlignment,
                       spacing: spacing,
                       content: content)
            } else {
                HStack(alignment: verticalAlignment,
                       spacing: spacing,
                       content: content)
            }
        }
    }
}

struct AdaptiveStack_Previews: PreviewProvider {
    static var previews: some View {
        AdaptiveStack(isAccessibilityCategory: true) {
            Text(verbatim: "Horizontal with normal font size")
            Text(verbatim: "but")
            Text(verbatim: "Vertical with large a11y font size")
        }
        .previewDisplayName("HStack")

        AdaptiveStack(isAccessibilityCategory: false) {
            Text(verbatim: "Horizontal with normal font size")
            Text(verbatim: "but")
            Text(verbatim: "Vertical with large a11y font size")
        }
        .previewDisplayName("VStack")
    }
}
