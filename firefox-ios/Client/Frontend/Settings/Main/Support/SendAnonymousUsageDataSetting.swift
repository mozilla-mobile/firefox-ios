// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Shared

class SendAnonymousUsageDataSetting: BoolSetting {
    private weak var settingsDelegate: SupportSettingsDelegate?

    var shouldSendUsageData: ((Bool) -> Void)?

    init(prefs: Prefs,
         delegate: SettingsDelegate?,
         theme: Theme,
         settingsDelegate: SupportSettingsDelegate?) {
        let statusText = NSMutableAttributedString()
        statusText.append(
            NSAttributedString(
                string: .SendUsageSettingMessage,
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
                string: .SendUsageSettingLink,
                attributes: [NSAttributedString.Key.foregroundColor: theme.colors.actionPrimary]
            )
        )

        self.settingsDelegate = settingsDelegate
        super.init(
            prefs: prefs,
            prefKey: AppConstants.prefSendUsageData,
            defaultValue: true,
            attributedTitleText: NSAttributedString(string: .SendUsageSettingTitle),
            attributedStatusText: statusText
        )

        setupSettingDidChange()

        // We make sure to set this on initialization, in case the setting is turned off
        // in which case, we would to make sure that users are opted out of experiments
        Experiments.setTelemetrySetting(prefs.boolForKey(AppConstants.prefSendUsageData) ?? true)
    }

    private func setupSettingDidChange() {
        self.settingDidChange = { [weak self] value in
            // AdjustHelper.setEnabled($0)
            DefaultGleanWrapper.shared.setUpload(isEnabled: value)
            Experiments.setTelemetrySetting(value)
            self?.shouldSendUsageData?(value)
        }
    }

    override var accessibilityIdentifier: String? {
        return AccessibilityIdentifiers.Settings.SendAnonymousUsageData.title
    }

    override var url: URL? {
        return SupportUtils.URLForTopic("adjust")
    }

    override func onClick(_ navigationController: UINavigationController?) {
        settingsDelegate?.askedToOpen(url: url, withTitle: title)
    }
}
