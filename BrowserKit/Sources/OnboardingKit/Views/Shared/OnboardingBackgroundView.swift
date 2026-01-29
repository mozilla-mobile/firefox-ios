// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common

// MARK: - OnboardingBackgroundView

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
            case .legacy, .modern, .japan:
                AnimatedGradientView(windowUUID: windowUUID, themeManager: themeManager)
            case .brandRefresh:
                ImageBackgroundView(windowUUID: windowUUID, themeManager: themeManager)
            }
        }
        .ignoresSafeArea()
        .listenToThemeChanges(theme: $theme, manager: themeManager, windowUUID: windowUUID)
    }
}

// MARK: - ImageBackgroundView

/// Image background view that selects asset based on theme.
private struct ImageBackgroundView: ThemeableView {
    @State var theme: Theme
    let windowUUID: WindowUUID
    var themeManager: ThemeManager

    init(windowUUID: WindowUUID, themeManager: ThemeManager) {
        self.windowUUID = windowUUID
        self.themeManager = themeManager
        self.theme = themeManager.getCurrentTheme(for: windowUUID)
    }

    var body: some View {
        GeometryReader { geometry in
            let assetName = imageName(for: theme.type)
            if let image = UIImage(named: assetName, in: .module, with: nil) ?? UIImage(named: assetName, in: .main, with: nil) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
                    .accessibilityHidden(true)
            }
        }
        .listenToThemeChanges(theme: $theme, manager: themeManager, windowUUID: windowUUID)
    }

    private func imageName(for themeType: ThemeType) -> String {
        switch themeType {
        case .light:
            return UX.Background.brandRefreshLight
        case .dark, .privateMode, .nightMode:
            return UX.Background.brandRefreshDark
        }
    }
}
