// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

struct ToggleSwitch {
    let mainView: UIImageView = {
        let background = UIImageView(image: UIImage.templateImageNamed("menu-customswitch-background"))
        background.contentMode = .scaleAspectFit
        return background
    }()

    private let foreground = UIImageView()

    init() {
        foreground.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        foreground.contentMode = .scaleAspectFit
        foreground.frame = mainView.frame
        mainView.isAccessibilityElement = true
        mainView.addSubview(foreground)
        setOn(false)
    }

    func setOn(_ on: Bool) {
        foreground.image = on ? UIImage(named: "menu-customswitch-on") : UIImage(named: "menu-customswitch-off")
        mainView.accessibilityIdentifier = on ? "enabled" : "disabled"
        mainView.tintColor = on ? UIColor.theme.general.controlTint : UIColor.theme.general.switchToggle }
}
