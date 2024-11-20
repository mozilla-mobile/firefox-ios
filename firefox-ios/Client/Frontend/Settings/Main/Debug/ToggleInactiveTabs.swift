// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

class ToggleInactiveTabs: HiddenSetting, FeatureFlaggable {
    private weak var settingsDelegate: SharedSettingsDelegate?

    init(settings: SettingsTableViewController,
         settingsDelegate: SharedSettingsDelegate) {
        self.settingsDelegate = settingsDelegate
        super.init(settings: settings)
    }

    override var title: NSAttributedString? {
        let toNewStatus = featureFlags.isFeatureEnabled(.inactiveTabs, checking: .userOnly) ? "OFF" : "ON"
        return NSAttributedString(string: "Toggle inactive tabs \(toNewStatus)",
                                  attributes: [NSAttributedString.Key.foregroundColor: theme.colors.textPrimary])
    }

    override func onClick(_ navigationController: UINavigationController?) {
        let newStatus = !featureFlags.isFeatureEnabled(.inactiveTabs, checking: .userOnly)
        featureFlags.set(feature: .inactiveTabs, to: newStatus)
        settingsDelegate?.askedToReload()
    }
}
