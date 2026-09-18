// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI

/// A padded, rounded container used by the SwiftUI settings screens, with an optional image
/// pinned to its bottom trailing corner.
struct RoundedCard<Content: View>: View {
    var background: Color
    var cornerRadius: CGFloat
    var padding: CGFloat
    @ViewBuilder var content: () -> Content
    var overlay: (() -> Image)?

    var body: some View {
        content()
            .padding(.vertical, padding)
            .padding(.horizontal, padding)
            .background(
                background
            ).overlay(alignment: .bottomTrailing) {
                overlay?()
            }
            .cornerRadius(cornerRadius)
    }
}
