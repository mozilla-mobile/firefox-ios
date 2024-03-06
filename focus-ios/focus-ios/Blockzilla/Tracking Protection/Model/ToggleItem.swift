/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

class ToggleItem {
    let title: String
    let subtitle: String?
    let settingsKey: SettingsToggle

    init(label: String, settingsKey: SettingsToggle, subtitle: String? = nil) {
        self.title = label
        self.settingsKey = settingsKey
        self.subtitle = subtitle
    }
}

extension ToggleItem {
    var settingsValue: Bool {
        get { Settings.getToggle(settingsKey) }
        set { Settings.set(newValue, forToggle: settingsKey) }
    }
}
