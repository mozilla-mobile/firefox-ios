// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared

class PrivacyNoticeUpdate: HiddenSetting {
    override var title: NSAttributedString? {
        return NSAttributedString(string: "Update latest Privacy Notice timestamp to now")
    }

    override init(settings: SettingsTableViewController) {
        super.init(settings: settings)
    }

    override func onClick(_ navigationController: UINavigationController?) {
        settings.profile?.prefs.setBool(true, forKey: PrefsKeys.PrivacyNotice.privacyNoticeUpdateDebugOverride)
    }
}
