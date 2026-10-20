// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI

/// Card layout that keeps the buttons pinned to the bottom at their ideal height,
/// while the content fills and scrolls within the remaining space.
/// The content closure receives the height available to the scrollable area.
struct OnboardingCardLayout<Content: View, Buttons: View>: View {
    private let horizontalPadding: CGFloat
    private let content: (CGFloat) -> Content
    private let buttons: Buttons

    init(
        horizontalPadding: CGFloat = UX.CardView.cardHorizontalPadding,
        @ViewBuilder content: @escaping (CGFloat) -> Content,
        @ViewBuilder buttons: () -> Buttons
    ) {
        self.horizontalPadding = horizontalPadding
        self.content = content
        self.buttons = buttons()
    }

    var body: some View {
        VStack(spacing: 0) {
            GeometryReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    content(proxy.size.height)
                        .frame(maxWidth: .infinity, minHeight: proxy.size.height)
                }
                .scrollBounceBehavior(basedOnSize: true)
            }

            buttons
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, horizontalPadding)
    }
}
