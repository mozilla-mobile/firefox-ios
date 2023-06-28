// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

class TogglePullToRefresh: HiddenSetting, FeatureFlaggable {
    private weak var settingsDelegate: DebugSettingsDelegate?

    init(settings: SettingsTableViewController,
         settingsDelegate: DebugSettingsDelegate) {
        self.settingsDelegate = settingsDelegate
        super.init(settings: settings)
    }

    override var title: NSAttributedString? {
        let toNewStatus = featureFlags.isFeatureEnabled(.pullToRefresh, checking: .userOnly) ? "OFF" : "ON"
        return NSAttributedString(string: "Toggle Pull to Refresh \(toNewStatus)",
                                  attributes: [NSAttributedString.Key.foregroundColor: theme.colors.textPrimary])
    }

    override func onClick(_ navigationController: UINavigationController?) {
        let newStatus = !featureFlags.isFeatureEnabled(.pullToRefresh, checking: .userOnly)
        featureFlags.set(feature: .pullToRefresh, to: newStatus)
        if CoordinatorFlagManager.isSettingsCoordinatorEnabled {
            settingsDelegate?.askedToReload()
        } else {
            updateCell(navigationController)
        }
    }
}
