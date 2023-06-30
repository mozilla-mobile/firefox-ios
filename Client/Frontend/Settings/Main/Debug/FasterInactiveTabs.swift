// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared

class FasterInactiveTabs: HiddenSetting {
    private weak var settingsDelegate: DebugSettingsDelegate?

    init(settings: SettingsTableViewController,
         settingsDelegate: DebugSettingsDelegate) {
        self.settingsDelegate = settingsDelegate
        super.init(settings: settings)
    }

    override var title: NSAttributedString? {
        let isFasterEnabled = UserDefaults.standard.bool(forKey: PrefsKeys.FasterInactiveTabsOverride)
        let buttonTitle = isFasterEnabled ? "Set Inactive Tab Timeout to Default" : "Set Inactive Tab Timeout to 10s"
        return NSAttributedString(string: buttonTitle, attributes: [NSAttributedString.Key.foregroundColor: theme.colors.textPrimary])
    }

    override func onClick(_ navigationController: UINavigationController?) {
        let isFasterEnabled = UserDefaults.standard.bool(forKey: PrefsKeys.FasterInactiveTabsOverride)
        UserDefaults.standard.set(!isFasterEnabled, forKey: PrefsKeys.FasterInactiveTabsOverride)
        if CoordinatorFlagManager.isSettingsCoordinatorEnabled {
            settingsDelegate?.askedToReload()
        } else {
            updateCell(navigationController)
        }
    }
}
