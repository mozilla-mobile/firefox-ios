// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation

class ChangeToChinaSetting: HiddenSetting {
    override var title: NSAttributedString? {
        guard let theme else { return nil }
        return NSAttributedString(
            string: "Toggle China version (needs restart)",
            attributes: [NSAttributedString.Key.foregroundColor: theme.colors.textPrimary]
        )
    }

    override func onClick(_ navigationController: UINavigationController?) {
        if UserDefaults.standard.bool(forKey: AppInfo.debugPrefIsChinaEdition) {
            UserDefaults.standard.removeObject(forKey: AppInfo.debugPrefIsChinaEdition)
        } else {
            UserDefaults.standard.set(true, forKey: AppInfo.debugPrefIsChinaEdition)
        }
    }
}
