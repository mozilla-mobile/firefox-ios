// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

extension TabCell: NotificationThemeable {
    func applyTheme() {
        backgroundHolder.backgroundColor = UIColor.theme.tabTray.cellBackground
        screenshotView.backgroundColor = UIColor.theme.tabTray.screenshotBackground

        let activeBGColor = isPrivate ? UIColor.theme.ecosia.tabSelectedPrivateBackground : UIColor.theme.ecosia.tabSelectedBackground
        title.backgroundColor = isSelectedTab ? activeBGColor : UIColor.theme.ecosia.tabBackground

        titleText.textColor = isSelectedTab ? UIColor.theme.ecosia.primaryTextInverted : UIColor.theme.ecosia.primaryText
        favicon.tintColor = isSelectedTab ? UIColor.theme.ecosia.primaryTextInverted : UIColor.theme.ecosia.primaryText
        closeButton.tintColor = isSelectedTab ? UIColor.theme.ecosia.primaryTextInverted : UIColor.theme.ecosia.primaryText

        if isSelectedTab {
            // This creates a border around a tabcell. Using the shadow craetes a border _outside_ of the tab frame.
            layer.masksToBounds = false
            layer.shadowOpacity = 1
            layer.shadowRadius = 0 // A 0 radius creates a solid border instead of a gradient blur
            // create a frame that is "BorderWidth" size bigger than the cell
            layer.shadowOffset = CGSize(width: -TabCell.borderWidth, height: -TabCell.borderWidth)
            layer.shadowColor = activeBGColor.cgColor
        } else if LegacyThemeManager.instance.current.isDark  {
            layer.masksToBounds = true
            layer.shadowOpacity = 0
            layer.shadowOffset = .zero
        } else {
            layer.masksToBounds = false
            layer.shadowOffset = .init(width: 0, height: 1)
            layer.shadowOpacity = 1.0
            layer.shadowColor = UIColor(white: 0.059, alpha: 0.18).cgColor
            layer.shadowRadius = 2
        }
    }
}
