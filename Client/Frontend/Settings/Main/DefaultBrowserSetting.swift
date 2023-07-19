// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Shared

class DefaultBrowserSetting: Setting {
    override var accessibilityIdentifier: String? { return "DefaultBrowserSettings" }

    init(theme: Theme) {
        super.init(title: NSAttributedString(string: String.DefaultBrowserMenuItem,
                                             attributes: [NSAttributedString.Key.foregroundColor: theme.colors.actionPrimary]))
    }

    override func onClick(_ navigationController: UINavigationController?) {
        TelemetryWrapper.gleanRecordEvent(category: .action,
                                          method: .open,
                                          object: .settingsMenuSetAsDefaultBrowser)
        DefaultApplicationHelper().openSettings()
    }
}
