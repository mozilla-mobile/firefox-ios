// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

class ReaderModeThemeButton: UIButton, ThemeApplicable {
    var readerModeTheme: ReaderModeTheme!

    var fontType: ReaderModeFontType = .sansSerif {
        didSet {
            switch fontType {
            case .sansSerif,
                 .sansSerifBold:
                titleLabel?.font = UIFont(name: "SF-Pro", size: DynamicFontHelper.defaultHelper.ReaderStandardFontSize)
            case .serif,
                 .serifBold:
                titleLabel?.font = UIFont(name: "NewYorkMedium-Regular", size: DynamicFontHelper.defaultHelper.ReaderStandardFontSize)
            }
        }
    }

    convenience init(readerModeTheme: ReaderModeTheme, appTheme: Theme) {
        self.init(frame: .zero)
        self.readerModeTheme = readerModeTheme

        accessibilityHint = .ReaderModeStyleChangeColorSchemeAccessibilityHint
        applyTheme(theme: appTheme)
    }

    func applyTheme(theme: Theme) {
        switch readerModeTheme {
        case .light:
            setTitle(.ReaderModeStyleLightLabel, for: [])
            // TODO: Fix color for title and background
            setTitleColor(FXColors.DarkGrey90, for: .normal)
            backgroundColor = FXColors.LightGrey10
        case .sepia:
            setTitle(.ReaderModeStyleSepiaLabel, for: [])
            setTitleColor(theme.colors.textPrimary, for: .normal)
            backgroundColor = theme.colors.layerSepia
        case .dark:
            setTitle(.ReaderModeStyleDarkLabel, for: [])
            // TODO: Fix color for title and background
            setTitleColor(FXColors.LightGrey05, for: [])
            backgroundColor = FXColors.DarkGrey60
        case .none:
            break
        }
    }
}
