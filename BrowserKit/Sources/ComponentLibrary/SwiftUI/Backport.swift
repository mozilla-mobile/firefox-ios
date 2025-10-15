// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI

public struct CompatibilityBridge<Content> {
    let content: Content
}

public extension CompatibilityBridge where Content: View {
    @MainActor
    @ViewBuilder
    // TODO: needs to be refactored.
    func glassButtonStyle(tint: Color) -> some View {
        if #available(iOS 26, *) {
            content.buttonStyle(.glassProminent).tint(tint)
        } else {
            content.buttonStyle(.plain)
        }
    }

    @MainActor
    @ViewBuilder
    func cardBackground(_ color: Color, cornerRadius: CGFloat) -> some View {
        if #available(iOS 26, *) {
            content.glassEffect(.regular.tint(color), in: .rect(cornerRadius: cornerRadius))
        } else {
            content.background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(color)
                    .accessibilityHidden(true)
            )
        }
    }
}
