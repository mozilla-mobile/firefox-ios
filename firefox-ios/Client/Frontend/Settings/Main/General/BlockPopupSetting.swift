// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared

class BlockPopupSetting: BoolSetting {
    init(prefs: Prefs) {
        let currentValue = prefs.boolForKey(PrefsKeys.KeyBlockPopups)
        let didChange = { (isEnabled: Bool) in
            NotificationCenter.default.post(name: .BlockPopup,
                                            object: nil)
        }

        super.init(title: .AppSettingsBlockPopups,
                   prefs: prefs,
                   prefKey: PrefsKeys.KeyBlockPopups,
                   defaultValue: currentValue ?? true) { isEnabled in
            didChange(isEnabled)
        }
    }

    override var accessibilityIdentifier: String? {
        return AccessibilityIdentifiers.Settings.BlockPopUp.title
    }
}
