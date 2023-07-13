// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Shared

class PrivacyPolicySetting: Setting {
    private weak var settingsDelegate: PrivacySettingsDelegate?

    override var url: URL? {
        return URL(string: "https://www.mozilla.org/privacy/firefox/")
    }

    init(theme: Theme,
         settingsDelegate: PrivacySettingsDelegate?) {
        self.settingsDelegate = settingsDelegate
        super.init(title: NSAttributedString(string: .AppSettingsPrivacyPolicy,
                                             attributes: [NSAttributedString.Key.foregroundColor: theme.colors.textPrimary]))
    }

    override func onClick(_ navigationController: UINavigationController?) {
        if CoordinatorFlagManager.isSettingsCoordinatorEnabled {
            settingsDelegate?.askedToOpen(url: url, withTitle: title)
            return
        }

        setUpAndPushSettingsContentViewController(navigationController, self.url)
    }
}
