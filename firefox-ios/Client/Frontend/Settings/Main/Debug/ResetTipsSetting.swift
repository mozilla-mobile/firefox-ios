// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Shared
import TipKit
import UIKit

class ResetTipsSetting: HiddenSetting {
    override var accessibilityIdentifier: String? { return "ResetTips.Setting" }

    private var isResetScheduled: Bool {
        return settings.profile?.prefs.boolForKey(PrefsKeys.Tips.shouldResetDatastore) ?? false
    }

    override var title: NSAttributedString? {
        guard let theme else { return nil }
        return NSAttributedString(
            string: "Reset all tips",
            attributes: [.foregroundColor: theme.colors.textPrimary]
        )
    }

    override var status: NSAttributedString? {
        guard let theme else { return nil }
        let label = isResetScheduled ? "Tips reset on next app launch" : "Tap to reset on next app launch"
        return NSAttributedString(
            string: label,
            attributes: [.foregroundColor: theme.colors.textSecondary]
        )
    }

    override func onClick(_ navigationController: UINavigationController?) {
        settings.profile?.prefs.setBool(true, forKey: PrefsKeys.Tips.shouldResetDatastore)
        settings.tableView.reloadData()
    }

    /// Performs the Tips reset scheduled by this setting, if any.
    /// This method must be called before `Tips.configure()` otherwise it won't have effect.
    @available(iOS 17.0, *)
    static func resetDatastoreIfNeeded(prefs: Prefs) {
        #if MOZ_CHANNEL_beta || MOZ_CHANNEL_developer
        guard prefs.boolForKey(PrefsKeys.Tips.shouldResetDatastore) ?? false else { return }

        // Cleared first so a failing reset isn't retried on every launch.
        prefs.removeObjectForKey(PrefsKeys.Tips.shouldResetDatastore)
        do {
            try Tips.resetDatastore()
        } catch {}
        #endif
    }
}
