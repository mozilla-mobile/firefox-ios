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

    var shouldUsePrivateOverride: Bool {
        return true
    }

    var shouldBeInPrivateTheme: Bool {
        return false
    }

    private func retrieveTheme() -> Theme {
        if shouldUsePrivateOverride {
            return themeManager.resolvedTheme(with: false)
        } else {
            return themeManager.getCurrentTheme(for: windowUUID)
        }
    }

    override func applyTheme() {
        super.applyTheme()
        let theme = retrieveTheme()

        setupNavigationBarAppearance(theme: theme)
    }
}
