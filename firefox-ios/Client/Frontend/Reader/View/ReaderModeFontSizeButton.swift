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

class ReaderModeFontSizeButton: ReaderModeSettingsButton {
    var fontSizeAction: FontSizeAction = .bigger

    convenience init(fontSizeAction: FontSizeAction) {
        self.init(frame: .zero)
        self.fontSizeAction = fontSizeAction

        switch fontSizeAction {
        case .smaller:
            configuration?.title = .ReaderModeStyleSmallerLabel
            accessibilityLabel = .ReaderModeStyleSmallerAccessibilityLabel
        case .bigger:
            configuration?.title = .ReaderModeStyleLargerLabel
            accessibilityLabel = .ReaderModeStyleLargerAccessibilityLabel
        case .reset:
            configuration?.title = .ReaderModeStyleFontSize
            accessibilityLabel = .ReaderModeResetFontSizeAccessibilityLabel
        }

        guard fontSizeAction != .reset else { return }

        sansSerifFont = FXFontStyles.Regular.title3.scaledFont()
        serifFont = UIFont(name: "NewYorkMedium-Regular",
                           size: FXFontStyles.Regular.title3.systemFont().pointSize)
    }

    // MARK: ThemeApplicable
    override public func applyTheme(theme: Theme) {
        configuration?.baseForegroundColor = theme.colors.textPrimary
        setNeedsUpdateConfiguration()
    }
}
