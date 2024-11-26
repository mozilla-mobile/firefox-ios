// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Shared

enum SendDataType {
    case usageData
    case crashReports
}

class SendDataSetting: BoolSetting {
    private weak var settingsDelegate: SupportSettingsDelegate?
    private let sendDataType: SendDataType

    var shouldSendData: ((Bool) -> Void)?

    init(prefs: Prefs,
         delegate: SettingsDelegate?,
         theme: Theme,
         settingsDelegate: SupportSettingsDelegate?,
         sendDataType: SendDataType) {
        var title: String
        var message: String
        var linkedText: String
        var prefKey: String

        switch sendDataType {
        case .usageData:
            title = .SendUsageSettingTitle
            message = .SendUsageSettingMessage
            linkedText = .SendUsageSettingLink
            prefKey = AppConstants.prefSendUsageData
        case .crashReports:
            title = .SendCrashReportsSettingTitle
            message = .SendCrashReportsSettingMessage
            linkedText = .SendCrashReportsSettingLink
            prefKey = AppConstants.prefSendCrashReports
        }

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

        self.sendDataType = sendDataType
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
            // AdjustHelper.setEnabled($0)
            DefaultGleanWrapper.shared.setUpload(isEnabled: value)
            Experiments.setTelemetrySetting(value)
            self?.shouldSendData?(value)
        }
    }

    override var accessibilityIdentifier: String? {
        switch sendDataType {
        case .usageData:
            return AccessibilityIdentifiers.Settings.SendData.sendAnonymousUsageDataTitle
        case .crashReports:
            return AccessibilityIdentifiers.Settings.SendData.sendCrashReportsTitle
        }
    }

    override var url: URL? {
        switch sendDataType {
        case .usageData:
            return SupportUtils.URLForTopic("adjust")
        case .crashReports:
            // TODO: FXIOS-10348 Firefox iOS: Manage Privacy Preferences in Settings
            return nil
        }
    }

    override func onClick(_ navigationController: UINavigationController?) {
        settingsDelegate?.askedToOpen(url: url, withTitle: title)
    }
}
