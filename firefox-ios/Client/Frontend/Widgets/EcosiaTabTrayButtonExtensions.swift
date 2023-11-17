// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit
import Shared

class PrivateModeButton: ToggleButton, PrivateModeUI {
    var offTint = UIColor.black
    var onTint = UIColor.black
    var isPrivate = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        accessibilityLabel = .TabTrayToggleAccessibilityLabel
        accessibilityHint = .TabTrayToggleAccessibilityHint
        setTitle(.localized(.privateTab), for: .normal)
        setTitleColor(LegacyThemeManager.instance.current.tabTray.tabTitleText, for: .normal)
        titleLabel?.font = .preferredFont(forTextStyle: .body)
        titleLabel?.adjustsFontForContentSizeCategory = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func applyUIMode(isPrivate: Bool, theme: Theme) {
        // isPrivate == isSelected
        self.isPrivate = isPrivate
        accessibilityValue = isSelected ? .TabTrayToggleAccessibilityValueOn : .TabTrayToggleAccessibilityValueOff
        updateColors()
    }
    
    func applyTheme(theme: Theme) {
        updateColors()
    }
}

extension PrivateModeButton {
    
    private func updateColors() {
        let color = isPrivate
        ? UIColor.legacyTheme.ecosia.primaryBackground
        : UIColor.legacyTheme.ecosia.primaryText
        
        setTitleColor(color, for: .normal)
        backgroundLayer.backgroundColor = isPrivate
            ? UIColor.legacyTheme.ecosia.privateButtonBackground.cgColor
            : UIColor.clear.cgColor
    }
}

