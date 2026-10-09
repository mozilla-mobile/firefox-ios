// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared

class MockBreachAlertsSetting: HiddenSetting {
    private weak var settingsDelegate: SharedSettingsDelegate?

    override var title: NSAttributedString? {
        let currentState = settings.profile?.prefs.boolForKey(PrefsKeys.useMockBreachAlerts) ?? false ? "TRUE" : "FALSE"
        return NSAttributedString(string: "Use Mock Breach Alerts: \(currentState)")
    }

    init(settings: SettingsTableViewController,
         settingsDelegate: SharedSettingsDelegate) {
        self.settingsDelegate = settingsDelegate
        super.init(settings: settings)
    }

    override func onClick(_ navigationController: UINavigationController?) {
        let currentState = settings.profile?.prefs.boolForKey(PrefsKeys.useMockBreachAlerts) ?? false
        settings.profile?.prefs.setBool(!currentState, forKey: PrefsKeys.useMockBreachAlerts)
        settingsDelegate?.askedToReload()
    }
}
