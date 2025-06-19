// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common

class ForceRSSyncSetting: HiddenSetting {
    override var title: NSAttributedString? {
        guard let theme else { return nil }
        // Not localized for now.
        return NSAttributedString(string: "Force Remote Settings Sync",
                                  attributes: [NSAttributedString.Key.foregroundColor: theme.colors.textPrimary])
    }

    override func onClick(_ navigationController: UINavigationController?) {
        let profile: Profile = AppContainer.shared.resolve()
        (profile as? BrowserProfile)?.serviceSyncCoordinator?.forceImmediateSync()
    }
}
