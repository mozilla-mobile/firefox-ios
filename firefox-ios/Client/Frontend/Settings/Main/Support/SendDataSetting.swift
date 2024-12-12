// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Glean
import Shared

enum SendDataType {
    case usageData
    case technicalData
    case crashReports
    case dailyUsagePing
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
        case .technicalData:
            title = .SendTechnicalDataSettingTitle
            message = String(format: .SendTechnicalDataSettingMessage, AppName.shortName.rawValue)
            linkedText = .SendTechnicalDataSettingLink
            prefKey = AppConstants.prefSendTechnicalData
        case .crashReports:
            title = .SendCrashReportsSettingTitle
            message = .SendCrashReportsSettingMessage
            linkedText = .SendCrashReportsSettingLink
            prefKey = AppConstants.prefSendCrashReports
        case .dailyUsagePing:
            title = .SendDailyUsagePingSettingTitle
            message = .SendDailyUsagePingSettingMessage
            linkedText = .SendDailyUsagePingSettingLink
            prefKey = AppConstants.prefSendDailyUsagePing
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

            if !value {
                self?.prefs?.removeObjectForKey(PrefsKeys.Usage.profileId)

                // set dummy uuid to make sure the previous one is deleted
                if let uuid = UUID(uuidString: "beefbeef-beef-beef-beef-beeefbeefbee") {
                    GleanMetrics.Usage.profileId.set(uuid)
                }
            }

            Experiments.setTelemetrySetting(value)
            self?.shouldSendData?(value)
        }
    }

    override var accessibilityIdentifier: String? {
        switch sendDataType {
        case .usageData:
            return AccessibilityIdentifiers.Settings.SendData.sendAnonymousUsageDataTitle
        case .technicalData:
            return AccessibilityIdentifiers.Settings.SendData.sendTechnicalDataTitle
        case .crashReports:
            return AccessibilityIdentifiers.Settings.SendData.sendCrashReportsTitle
        case .dailyUsagePing:
            return AccessibilityIdentifiers.Settings.SendData.sendDailyUsagePingTitle
        }
    }

    // TODO: FXIOS-10739 Firefox iOS: Use the correct links for Learn more buttons, in Manage Privacy Preferences screen
    override var url: URL? {
        switch sendDataType {
        case .usageData:
            return SupportUtils.URLForTopic("adjust")
        case .technicalData:
            return nil
        case .crashReports:
            return nil
        case .dailyUsagePing:
            return SupportUtils.URLForTopic("dau-ping-settings-mobile")
        }
    }

    override func onClick(_ navigationController: UINavigationController?) {
        settingsDelegate?.askedToOpen(url: url, withTitle: title)
    }
}
