// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

struct ToggleSwitch {
    let mainView: UIImageView = {
        let background = UIImageView(image: UIImage.templateImageNamed(ImageIdentifiers.customSwitchBackground))
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
        foreground.image = on ? UIImage(named: ImageIdentifiers.customSwitchOn) : UIImage(named: ImageIdentifiers.customSwitchOff)
        mainView.accessibilityIdentifier = on ? "enabled" : "disabled"
        mainView.tintColor = on ? UIColor.theme.general.controlTint : UIColor.theme.general.switchToggle }
}
