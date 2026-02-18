// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common

/// Image background view that selects asset based on theme.
struct ImageBackgroundView: ThemeableView {
    @State var theme: Theme
    let windowUUID: WindowUUID
    var themeManager: ThemeManager

    init(windowUUID: WindowUUID, themeManager: ThemeManager) {
        self.windowUUID = windowUUID
        self.themeManager = themeManager
        self.theme = themeManager.getCurrentTheme(for: windowUUID)
    }

    var body: some View {
        let assetName = imageName(for: theme.type)
        if let image = UIImage(named: assetName, in: .module, with: nil)
                      ?? UIImage(named: assetName, in: .main, with: nil) {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .clipped()
                .accessibilityHidden(true)
                .listenToThemeChanges(theme: $theme, manager: themeManager, windowUUID: windowUUID)
        }
    }

    private func imageName(for themeType: ThemeType) -> String {
        switch themeType {
        case .light:
            return OnboardingImageIdentifiers.backgroundBrandRefreshLight
        default:
            return OnboardingImageIdentifiers.backgroundBrandRefreshDark
        }
    }
}
