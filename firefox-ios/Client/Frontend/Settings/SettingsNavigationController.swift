// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common

class SettingsNavigationController: ThemedNavigationController {
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        NotificationCenter.default.post(name: .SettingsDismissed, object: self)
    }

    /// Settings are always shown in the regular theme, even while the user browses in private mode.
    override var shouldUsePrivateOverride: Bool {
        return true
    }

    override var shouldBeInPrivateTheme: Bool {
        return false
    }
}
