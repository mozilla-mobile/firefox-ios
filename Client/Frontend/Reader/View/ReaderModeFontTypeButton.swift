// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

class ReaderModeFontTypeButton: UIButton {
    var fontType: ReaderModeFontType = .sansSerif

    convenience init(fontType: ReaderModeFontType) {
        self.init(frame: .zero)

        self.fontType = fontType
        accessibilityHint = .ReaderModeStyleFontTypeAccessibilityLabel

        switch fontType {
        case .sansSerif,
             .sansSerifBold:
            setTitle(.ReaderModeStyleSansSerifFontType, for: [])
            let font = UIFont(name: "SF-Pro-Text-Regular", size: LegacyDynamicFontHelper.defaultHelper.ReaderStandardFontSize)
            titleLabel?.font = font
        case .serif,
             .serifBold:
            setTitle(.ReaderModeStyleSerifFontType, for: [])
            let font = UIFont(name: "NewYorkMedium-Regular", size: LegacyDynamicFontHelper.defaultHelper.ReaderStandardFontSize)
            titleLabel?.font = font
        }
    }
}
