// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit

class PrivateModeButton: ToggleButton, PrivateModeUI {
    override init(frame: CGRect) {
        super.init(frame: frame)
        accessibilityLabel = .TabsTray.TabTrayToggleAccessibilityLabel
        let maskImage = UIImage(named: StandardImageIdentifiers.Large.privateMode)?
            .withRenderingMode(.alwaysTemplate)
        setImage(maskImage, for: [])
        showsLargeContentViewer = true
        largeContentTitle = .TabsTray.TabTrayToggleAccessibilityLabel
        largeContentImage = maskImage
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func applyUIMode(isPrivate: Bool, theme: Theme) {
        let colors = theme.colors
        isSelected = isPrivate

        tintColor = isPrivate ? colors.iconOnColor : colors.iconPrimary
        imageView?.tintColor = tintColor

        if isSelected {
            accessibilityValue = .TabsTray.TabTrayToggleAccessibilityValueOn
        } else {
            accessibilityValue = .TabsTray.TabTrayToggleAccessibilityValueOff
        }
    }

    override func applyTheme(theme: Theme) {
        super.applyTheme(theme: theme)
        let colors = theme.colors
        tintColor = isSelected ? colors.iconOnColor : colors.iconPrimary
        imageView?.tintColor = tintColor
    }
}
