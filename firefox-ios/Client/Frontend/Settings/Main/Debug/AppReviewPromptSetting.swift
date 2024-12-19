// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared

class AppReviewPromptSetting: HiddenSetting {
    private weak var settingsDelegate: DebugSettingsDelegate?

    init(settings: SettingsTableViewController,
         settingsDelegate: DebugSettingsDelegate) {
        self.settingsDelegate = settingsDelegate
        super.init(settings: settings)
    }

    override var title: NSAttributedString? {
        guard let theme else { return nil }
        return NSAttributedString(
            string: "Toggle App Review (needs tab switch)",
            attributes: [NSAttributedString.Key.foregroundColor: theme.colors.textPrimary]
        )
    }

    override func onClick(_ navigationController: UINavigationController?) {
        UserDefaults.standard.set(true, forKey: PrefsKeys.ForceShowAppReviewPromptOverride)
        settingsDelegate?.askedToReload()
    }
}
