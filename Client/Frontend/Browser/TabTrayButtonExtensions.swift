/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

class PrivateModeButton: ToggleButton, Themeable {
    var light: Bool = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.accessibilityLabel = PrivateModeStrings.toggleAccessibilityLabel
        self.accessibilityHint = PrivateModeStrings.toggleAccessibilityHint
        let maskImage = UIImage(named: "smallPrivateMask")?.withRenderingMode(.alwaysTemplate)
        self.setImage(maskImage, for: UIControlState())
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func applyTheme(_ theme: Theme) {
        self.tintColor = UIColor.Browser.Tint.colorFor(theme)
        self.imageView?.tintColor = self.tintColor
        self.isSelected = theme == .Private
        self.accessibilityValue = self.isSelected ? PrivateModeStrings.toggleAccessibilityValueOn : PrivateModeStrings.toggleAccessibilityValueOff
    }
}

extension UIButton {
    static func newTabButton() -> UIButton {
        let newTab = UIButton()
        newTab.setImage(UIImage.templateImageNamed("quick_action_new_tab"), for: .normal)
        newTab.accessibilityLabel = NSLocalizedString("New Tab", comment: "Accessibility label for the New Tab button in the tab toolbar.")
        return newTab
    }
}

extension TabsButton {
    static func tabTrayButton() -> TabsButton {
        let tabsButton = TabsButton()
        tabsButton.countLabel.text = "0"
        tabsButton.accessibilityLabel = NSLocalizedString("Show Tabs", comment: "Accessibility Label for the tabs button in the tab toolbar")
        return tabsButton
    }
}
