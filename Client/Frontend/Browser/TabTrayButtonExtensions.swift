// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit
import Shared

class PrivateModeButton: ToggleButton, PrivateModeUI {
    override init(frame: CGRect) {
        super.init(frame: frame)
        accessibilityLabel = .TabTrayToggleAccessibilityLabel
        accessibilityHint = .TabTrayToggleAccessibilityHint
        let maskImage = UIImage(named: ImageIdentifiers.privateMaskSmall)?.withRenderingMode(.alwaysTemplate)
        setImage(maskImage, for: [])
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func applyUIMode(isPrivate: Bool, theme: Theme) {
        isSelected = isPrivate

        tintColor = isPrivate ? theme.colors.iconOnColor : theme.colors.iconPrimary
        imageView?.tintColor = tintColor

        accessibilityValue = isSelected ? .TabTrayToggleAccessibilityValueOn : .TabTrayToggleAccessibilityValueOff
    }

    func applyTheme(theme: Theme) {
        tintColor = isSelected ? theme.colors.iconOnColor : theme.colors.iconPrimary
        imageView?.tintColor = tintColor
    }
}
