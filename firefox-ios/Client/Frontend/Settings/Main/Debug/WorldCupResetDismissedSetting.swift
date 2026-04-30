// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common
import Shared

class WorldCupResetDismissedSetting: HiddenSetting {
    override var title: NSAttributedString? {
        guard let theme else { return nil }
        return NSAttributedString(
            string: "World Cup: Reset Dismissed Card",
            attributes: [.foregroundColor: theme.colors.textPrimary]
        )
    }

    override var status: NSAttributedString? {
        guard let theme else { return nil }
        let isDismissed = !(settings.profile?.prefs.boolForKey(PrefsKeys.HomepageSettings.WorldCupSection) ?? true)
        let label = isDismissed ? "Card is hidden — tap to restore" : "Card is visible"
        return NSAttributedString(
            string: label,
            attributes: [.foregroundColor: theme.colors.textSecondary]
        )
    }

    override func onClick(_ navigationController: UINavigationController?) {
        settings.profile?.prefs.removeObjectForKey(PrefsKeys.HomepageSettings.WorldCupSection)
        store.dispatch(
            WorldCupAction(
                windowUUID: settings.windowUUID,
                actionType: WorldCupActionType.didChangeHomepageSettings,
                shouldShowHomepageWorldCupSection: true
            )
        )
        settings.tableView.reloadData()
    }
}
