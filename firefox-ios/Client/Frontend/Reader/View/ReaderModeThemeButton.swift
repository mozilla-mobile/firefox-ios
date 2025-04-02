// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit

class ReaderModeThemeButton: ReaderModeSettingsButton {
    var readerModeTheme: ReaderModeTheme?

    convenience init(readerModeTheme: ReaderModeTheme) {
        self.init(frame: .zero)
        self.readerModeTheme = readerModeTheme

        accessibilityHint = .ReaderModeStyleChangeColorSchemeAccessibilityHint
    }

    override func applyTheme(theme: Theme) {
        // This view ignores the theme parameter. The view title and background is the
        // same color independently from the app theme, to accomplish this we create direct instances from
        // LightTheme for (.light and sepia) and DarkTheme for (.dark)
        let theme: Theme = readerModeTheme == .dark ? DarkTheme() : LightTheme()

        switch readerModeTheme {
        case .light:
            configuration?.title = .ReaderModeStyleLightLabel
            backgroundColor = theme.colors.layer1
        case .sepia:
            configuration?.title = .ReaderModeStyleSepiaLabel
            backgroundColor = theme.colors.layerSepia
        case .dark:
            configuration?.title = .ReaderModeStyleDarkLabel
            backgroundColor = theme.colors.layer1
        case .none:
            break
        }

        configuration?.baseForegroundColor = theme.colors.textPrimary
    }
}
