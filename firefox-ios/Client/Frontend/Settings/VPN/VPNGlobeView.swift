// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common

struct VPNGlobeView: View {
    private enum UX {
        static let iconSize: CGFloat = 44
        static let containerSize: CGFloat = 60
        static let containerCornerRadius: CGFloat = 16
    }

    let theme: Theme

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: UX.containerCornerRadius)
                .fill(
                    LinearGradient(gradient: theme.colors.gradientAccentSubtle.swiftUI,
                                   startPoint: .leading,
                                   endPoint: .trailing)
                )
                .background(.ultraThinMaterial,
                            in: RoundedRectangle(cornerRadius: UX.containerCornerRadius))

            Image(decorative: StandardImageIdentifiers.Large.globe)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: UX.iconSize, height: UX.iconSize)
                .foregroundStyle(
                    LinearGradient(gradient: theme.colors.gradientAccent.swiftUI,
                                   startPoint: .leading,
                                   endPoint: .trailing)
                )
        }
        .frame(width: UX.containerSize, height: UX.containerSize)
        .accessibilityHidden(true)
    }
}
