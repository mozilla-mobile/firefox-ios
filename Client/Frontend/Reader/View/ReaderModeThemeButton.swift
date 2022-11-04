// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

class ReaderModeThemeButton: UIButton {
    var theme: ReaderModeTheme!

    convenience init(theme: ReaderModeTheme) {
        self.init(frame: .zero)
        self.theme = theme

        setTitle(theme.rawValue, for: [])

        accessibilityHint = .ReaderModeStyleChangeColorSchemeAccessibilityHint

        switch theme {
        case .light:
            setTitle(.ReaderModeStyleLightLabel, for: [])
            setTitleColor(ReaderModeStyleViewModel.ThemeTitleColorLight, for: .normal)
            backgroundColor = ReaderModeStyleViewModel.ThemeBackgroundColorLight
        case .dark:
            setTitle(.ReaderModeStyleDarkLabel, for: [])
            setTitleColor(ReaderModeStyleViewModel.ThemeTitleColorDark, for: [])
            backgroundColor = ReaderModeStyleViewModel.ThemeBackgroundColorDark
        case .sepia:
            setTitle(.ReaderModeStyleSepiaLabel, for: [])
            setTitleColor(ReaderModeStyleViewModel.ThemeTitleColorSepia, for: .normal)
            backgroundColor = ReaderModeStyleViewModel.ThemeBackgroundColorSepia
        }
    }

    var fontType: ReaderModeFontType = .sansSerif {
        didSet {
            switch fontType {
            case .sansSerif,
                 .sansSerifBold:
                titleLabel?.font = UIFont(name: "SF-Pro-Text-Regular", size: DynamicFontHelper.defaultHelper.ReaderStandardFontSize)
            case .serif,
                 .serifBold:
                titleLabel?.font = UIFont(name: "NewYorkMedium-Regular", size: DynamicFontHelper.defaultHelper.ReaderStandardFontSize)
            }
        }
    }
}
