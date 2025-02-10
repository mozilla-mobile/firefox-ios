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

    override var accessibilityIdentifier: String? {
        return AccessibilityIdentifiers.Settings.PrivacyPolicy.title
    }

    init(theme: Theme,
         settingsDelegate: PrivacySettingsDelegate?) {
        self.settingsDelegate = settingsDelegate
        super.init(
            title: NSAttributedString(
                string: .AppSettingsPrivacyNotice,
                attributes: [NSAttributedString.Key.foregroundColor: theme.colors.textPrimary]
            )
        )
    }

    override func onClick(_ navigationController: UINavigationController?) {
        settingsDelegate?.askedToOpen(url: url, withTitle: title)
    }
}
