// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common

/// Background view that chooses gradient or image based on variant.
struct OnboardingBackgroundView: ThemeableView {
    @State var theme: Theme
    let windowUUID: WindowUUID
    var themeManager: ThemeManager
    let variant: OnboardingVariant

    init(
        windowUUID: WindowUUID,
        themeManager: ThemeManager,
        variant: OnboardingVariant
    ) {
        self.windowUUID = windowUUID
        self.themeManager = themeManager
        self.variant = variant
        self.theme = themeManager.getCurrentTheme(for: windowUUID)
    }

    var body: some View {
        Group {
            switch variant {
            case .brandRefresh:
                ImageBackgroundView(windowUUID: windowUUID, themeManager: themeManager)
            default:
                AnimatedGradientView(windowUUID: windowUUID, themeManager: themeManager)
            }
        }
        .ignoresSafeArea()
        .listenToThemeChanges(theme: $theme, manager: themeManager, windowUUID: windowUUID)
    }
}
