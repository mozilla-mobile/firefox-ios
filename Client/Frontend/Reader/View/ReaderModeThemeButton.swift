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
            setTitleColor(theme.colors.textPrimary, for: .normal)
            backgroundColor = theme.colors.layer1
        case .sepia:
            setTitle(.ReaderModeStyleSepiaLabel, for: [])
            setTitleColor(theme.colors.textPrimary, for: .normal)
            // TODO: wait for crystal color
            backgroundColor = ReaderModeStyleViewModel.ThemeBackgroundColorSepia
        case .dark:
            setTitle(.ReaderModeStyleDarkLabel, for: [])
            setTitleColor(theme.colors.textOnColor, for: [])
            // TODO: wait for crystal color
            backgroundColor = ReaderModeStyleViewModel.ThemeBackgroundColorDark
        case .none:
            break
        }
    }
}
