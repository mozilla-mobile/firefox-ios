// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit

class ReaderModeFontTypeButton: ReaderModeSettingsButton, ThemeApplicable {
    private var foregroundColorNormal: UIColor = .clear
    private var foregroundColorSelected: UIColor = .clear
    private var backgroundColorNormal: UIColor = .clear

    convenience init(fontType: ReaderModeFontType) {
        self.init(frame: .zero)

        accessibilityHint = .ReaderModeStyleFontTypeAccessibilityLabel

        switch fontType {
         case .sansSerif,
              .sansSerifBold:
            configuration?.title = .ReaderModeStyleSansSerifFontType
            accessibilityIdentifier = AccessibilityIdentifiers.ReaderMode.sansSerifFontButton
         case .serif,
              .serifBold:
            configuration?.title = .ReaderModeStyleSerifFontType
            accessibilityIdentifier = AccessibilityIdentifiers.ReaderMode.serifFontButton
         }

        configure(fontType: fontType)
    }

    override public func updateConfiguration() {
        guard var updatedConfiguration = configuration else {
            return
        }

        switch state {
        case [.selected]:
            updatedConfiguration.baseForegroundColor = foregroundColorSelected
        default:
            updatedConfiguration.baseForegroundColor = foregroundColorNormal
        }

        updatedConfiguration.background.backgroundColor = backgroundColorNormal
        configuration = updatedConfiguration
    }

    // MARK: ThemeApplicable
    public func applyTheme(theme: Theme) {
        foregroundColorNormal = theme.colors.textDisabled
        foregroundColorSelected = theme.colors.textPrimary
        backgroundColorNormal = .clear
        setNeedsUpdateConfiguration()
    }
}
