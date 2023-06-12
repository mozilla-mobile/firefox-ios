// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared

class NotificationsSetting: Setting {
    override var accessoryView: UIImageView? {
        return SettingDisclosureUtility.buildDisclosureIndicator(theme: theme)
    }

    override var accessibilityIdentifier: String? {
        return AccessibilityIdentifiers.Settings.Notifications.title
    }

    let profile: Profile

    init(theme: Theme, profile: Profile) {
        self.profile = profile
        super.init(title: NSAttributedString(string: .Settings.Notifications.Title,
                                             attributes: [NSAttributedString.Key.foregroundColor: theme.colors.textPrimary]))
    }

    override func onClick(_ navigationController: UINavigationController?) {
        let viewController = NotificationsSettingsViewController(prefs: profile.prefs,
                                                                 hasAccount: profile.hasAccount())
        navigationController?.pushViewController(viewController, animated: true)
    }
}
