// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common

final class VPNSettingsViewController: SettingsTableViewController {
    init(windowUUID: WindowUUID) {
        super.init(style: .grouped, windowUUID: windowUUID)
        self.title = .VPN.Settings.Title
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var theme: Theme {
        themeManager.getCurrentTheme(for: windowUUID)
    }
}
