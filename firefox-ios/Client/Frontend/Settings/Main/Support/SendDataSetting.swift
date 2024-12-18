// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Glean
import Shared

class SendDataSetting: BoolSetting {
    private weak var settingsDelegate: SupportSettingsDelegate?
    private var a11yId: String
    private var learnMoreURL: URL?

    var shouldSendData: ((Bool) -> Void)?

    init(prefs: Prefs,
         delegate: SettingsDelegate?,
         theme: Theme,
         settingsDelegate: SupportSettingsDelegate?,
         title: String,
         message: String,
         linkedText: String,
         prefKey: String,
         a11yId: String,
         learnMoreURL: URL?) {
        let statusText = NSMutableAttributedString()
        statusText.append(
            NSAttributedString(
                string: message,
                attributes: [NSAttributedString.Key.foregroundColor: theme.colors.textSecondary]
            )
        )
        statusText.append(
            NSAttributedString(
                string: " "
            )
        )
        statusText.append(
            NSAttributedString(
                string: linkedText,
                attributes: [NSAttributedString.Key.foregroundColor: theme.colors.actionPrimary]
            )
        )

        self.a11yId = a11yId
        self.learnMoreURL = learnMoreURL
        self.settingsDelegate = settingsDelegate
        super.init(
            prefs: prefs,
            prefKey: prefKey,
            defaultValue: true,
            attributedTitleText: NSAttributedString(string: title),
            attributedStatusText: statusText
        )

        setupSettingDidChange()

        // We make sure to set this on initialization, in case the setting is turned off
        // in which case, we would to make sure that users are opted out of experiments
        Experiments.setTelemetrySetting(prefs.boolForKey(prefKey) ?? true)
    }

    private func setupSettingDidChange() {
        self.settingDidChange = { [weak self] value in
            self?.shouldSendData?(value)
        }
    }

    override var accessibilityIdentifier: String? {
        return a11yId
    }

    override var url: URL? {
        return learnMoreURL
    }

    override func onClick(_ navigationController: UINavigationController?) {
        settingsDelegate?.askedToOpen(url: url, withTitle: title)
    }
}
