/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

class BlockerToggle {
    let toggle = UISwitch()
    let label: String
    let setting: SettingsToggle
    let subtitle: String?
    
    init(label: String, setting: SettingsToggle, subtitle: String? = nil) {
        self.label = label
        self.setting = setting
        self.subtitle = subtitle
        toggle.accessibilityIdentifier = "BlockerToggle.\(setting.rawValue)"
        toggle.onTintColor = UIConstants.colors.toggleOn
        toggle.tintColor = UIConstants.colors.toggleOff
    }
}
