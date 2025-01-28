// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit
import Shared

class ReaderModeThemeButton: UIButton {
    var readerModeTheme: ReaderModeTheme?

    var fontType: ReaderModeFontType = .sansSerif {
        didSet {
            switch fontType {
            case .sansSerif,
                 .sansSerifBold:
                titleLabel?.font = UIFont(
                    name: "SF-Pro",
                    size: LegacyDynamicFontHelper.defaultHelper.ReaderStandardFontSize
                )
            case .serif,
                 .serifBold:
                titleLabel?.font = UIFont(
                    name: "NewYorkMedium-Regular",
                    size: LegacyDynamicFontHelper.defaultHelper.ReaderStandardFontSize
                )
            }
        }
    }

    convenience init(readerModeTheme: ReaderModeTheme) {
        self.init(frame: .zero)
        self.readerModeTheme = readerModeTheme

        accessibilityHint = .ReaderModeStyleChangeColorSchemeAccessibilityHint
        applyTheme()
    }

    func applyTheme() {
        // This view doesn't follow the ThemeApplicable protocol. The view title and background is the
        // same color independently from the app theme, to accomplish this we create direct instances from
        // LightTheme for (.light and sepia) and DarkTheme for (.dark)
        let theme: Theme = readerModeTheme == .dark ? DarkTheme() : LightTheme()

        switch readerModeTheme {
        case .light:
            setTitle(.ReaderModeStyleLightLabel, for: [])
            setTitleColor(theme.colors.textPrimary, for: .normal)
            backgroundColor = theme.colors.layer1
        case .sepia:
            setTitle(.ReaderModeStyleSepiaLabel, for: [])
            setTitleColor(theme.colors.textPrimary, for: .normal)
            backgroundColor = theme.colors.layerSepia
        case .dark:
            setTitle(.ReaderModeStyleDarkLabel, for: [])
            setTitleColor(theme.colors.textPrimary, for: [])
            backgroundColor = theme.colors.layer1
        case .none:
            break
        }
    }
}
