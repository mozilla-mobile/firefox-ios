// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import UIKit

class PrivateModeButton: ToggleButton, NotificationThemeable, PrivateModeUI {
    var offTint = UIColor.black
    var onTint = UIColor.black

    override init(frame: CGRect) {
        super.init(frame: frame)
        accessibilityLabel = .TabTrayToggleAccessibilityLabel
        accessibilityHint = .TabTrayToggleAccessibilityHint
        let maskImage = UIImage(named: "smallPrivateMask")?.withRenderingMode(.alwaysTemplate)
        setImage(maskImage, for: [])
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func applyUIMode(isPrivate: Bool) {
        isSelected = isPrivate

        tintColor = isPrivate ? onTint : offTint
        imageView?.tintColor = tintColor

        accessibilityValue = isSelected ? .TabTrayToggleAccessibilityValueOn : .TabTrayToggleAccessibilityValueOff
    }

    func applyTheme() {
        tintColor = isSelected ? onTint : offTint
        imageView?.tintColor = tintColor
    }
}

extension UIButton {
    static func newTabButton() -> UIButton {
        let newTab = UIButton()
        newTab.setImage(UIImage.templateImageNamed(ImageIdentifiers.newTab), for: .normal)
        newTab.accessibilityLabel = .TabTrayButtonNewTabAccessibilityLabel
        return newTab
    }
}

extension TabsButton {
    static func tabTrayButton() -> TabsButton {
        let tabsButton = TabsButton()
        tabsButton.countLabel.text = "0"
        tabsButton.accessibilityLabel = .TabTrayButtonShowTabsAccessibilityLabel
        return tabsButton
    }
}
