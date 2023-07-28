// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

enum FontSizeAction {
    case smaller
    case reset
    case bigger
}

class ReaderModeFontSizeButton: UIButton {
    var fontSizeAction: FontSizeAction = .bigger

    convenience init(fontSizeAction: FontSizeAction) {
        self.init(frame: .zero)
        self.fontSizeAction = fontSizeAction

        switch fontSizeAction {
        case .smaller:
            setTitle(.ReaderModeStyleSmallerLabel, for: [])
            accessibilityLabel = .ReaderModeStyleSmallerAccessibilityLabel
        case .bigger:
            setTitle(.ReaderModeStyleLargerLabel, for: [])
            accessibilityLabel = .ReaderModeStyleLargerAccessibilityLabel
        case .reset:
            accessibilityLabel = .ReaderModeResetFontSizeAccessibilityLabel
        }

        titleLabel?.font = UIFont(name: "SF-Pro-Text-Regular", size: LegacyDynamicFontHelper.defaultHelper.ReaderBigFontSize)
    }
}
