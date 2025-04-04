// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit

enum FontSizeAction {
    case smaller
    case reset
    case bigger
}

class ReaderModeFontSizeButton: ReaderModeSettingsButton, ThemeApplicable {
    var fontSizeAction: FontSizeAction = .bigger

    convenience init(fontSizeAction: FontSizeAction) {
        self.init(frame: .zero)
        self.fontSizeAction = fontSizeAction

        switch fontSizeAction {
        case .smaller:
            configuration?.title = .ReaderModeStyleSmallerLabel
            accessibilityLabel = .ReaderModeStyleSmallerAccessibilityLabel
            accessibilityIdentifier = AccessibilityIdentifiers.ReaderMode.smallerFontSizeButton
        case .bigger:
            configuration?.title = .ReaderModeStyleLargerLabel
            accessibilityLabel = .ReaderModeStyleLargerAccessibilityLabel
            accessibilityIdentifier = AccessibilityIdentifiers.ReaderMode.biggerFontSizeButton
        case .reset:
            configuration?.title = .ReaderModeStyleFontSize
            accessibilityLabel = .ReaderModeResetFontSizeAccessibilityLabel
            accessibilityIdentifier = AccessibilityIdentifiers.ReaderMode.resetFontSizeButton
        }

        guard fontSizeAction != .reset else { return }

        sansSerifFont = FXFontStyles.Regular.title3.scaledFont()
        serifFont = UIFont(name: UX.serifFontName,
                           size: FXFontStyles.Regular.title3.systemFont().pointSize)
    }

    // MARK: ThemeApplicable
    public func applyTheme(theme: Theme) {
        configuration?.baseForegroundColor = theme.colors.textPrimary
        setNeedsUpdateConfiguration()
    }
}
