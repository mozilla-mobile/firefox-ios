// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared

class ResetWallpaperOnboardingPage: HiddenSetting {
    private weak var settingsDelegate: DebugSettingsDelegate?

    init(settings: SettingsTableViewController,
         settingsDelegate: DebugSettingsDelegate) {
        self.settingsDelegate = settingsDelegate
        super.init(settings: settings)
    }

    override var title: NSAttributedString? {
        guard let theme else { return nil }
        let seenStatus = UserDefaults.standard.bool(forKey: PrefsKeys.Wallpapers.OnboardingSeenKey) ? "seen" : "unseen"
        return NSAttributedString(string: "Reset wallpaper onboarding sheet (\(seenStatus))",
                                  attributes: [NSAttributedString.Key.foregroundColor: theme.colors.textPrimary])
    }

    override func onClick(_ navigationController: UINavigationController?) {
        UserDefaults.standard.set(false, forKey: PrefsKeys.Wallpapers.OnboardingSeenKey)
        settingsDelegate?.askedToReload()
    }
}
