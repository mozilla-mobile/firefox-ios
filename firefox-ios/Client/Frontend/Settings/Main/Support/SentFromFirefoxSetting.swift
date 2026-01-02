// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Shared

final class SentFromFirefoxSetting: BoolSetting {
    private weak var settingsDelegate: SupportSettingsDelegate?

    init(prefs: Prefs,
         delegate: SettingsDelegate?,
         theme: Theme,
         settingsDelegate: SupportSettingsDelegate?) {
        let titleString = String.localizedStringWithFormat(.SentFromFirefox.SocialShare.SocialSettingsToggleTitle,
                                                           AppName.shortName.rawValue,
                                                           String.SentFromFirefox.SocialMediaApp.WhatsApp)
        let subtitleString = String.localizedStringWithFormat(.SentFromFirefox.SocialShare.SocialSettingsToggleSubtitle,
                                                              AppName.shortName.rawValue,
                                                              String.SentFromFirefox.SocialMediaApp.WhatsApp)

        let titleAttributedString = NSAttributedString(string: titleString)
        let subtitleAttributedString = NSAttributedString(
            string: subtitleString,
            attributes: [NSAttributedString.Key.foregroundColor: theme.colors.textSecondary]
        )

        self.settingsDelegate = settingsDelegate

        super.init(
            prefs: prefs,
            prefKey: PrefsKeys.Settings.sentFromFirefoxWhatsApp,
            defaultValue: true,
            attributedTitleText: titleAttributedString,
            attributedStatusText: subtitleAttributedString,
            featureFlagName: .sentFromFirefox
        )
    }

    override var accessibilityIdentifier: String? {
        return AccessibilityIdentifiers.Settings.SentFromFirefox.whatsApp
    }
}
