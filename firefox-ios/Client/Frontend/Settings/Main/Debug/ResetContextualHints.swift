// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared

class ResetContextualHints: HiddenSetting {
    let profile: Profile?

    override var accessibilityIdentifier: String? { return "ResetContextualHints.Setting" }

    override var title: NSAttributedString? {
        guard let theme else { return nil }
        return NSAttributedString(
            string: "Reset all contextual hints",
            attributes: [NSAttributedString.Key.foregroundColor: theme.colors.textPrimary])
    }

    override init(settings: SettingsTableViewController) {
        self.profile = settings.profile
        super.init(settings: settings)
    }

    override func onClick(_ navigationController: UINavigationController?) {
        PrefsKeys.ContextualHints.allCases.forEach {
            self.profile?.prefs.removeObjectForKey($0.rawValue)
        }
    }
}
