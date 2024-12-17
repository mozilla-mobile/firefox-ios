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
            message = String(format: .SendTechnicalDataSettingMessage,
                             MozillaName.shortName.rawValue,
                             AppName.shortName.rawValue)
            linkedText = .SendTechnicalDataSettingLink
            prefKey = AppConstants.prefSendTechnicalData
        case .crashReports:
            title = .SendCrashReportsSettingTitle
            message = String(format: .SendCrashReportsSettingMessage, MozillaName.shortName.rawValue)
            linkedText = .SendCrashReportsSettingLink
            prefKey = AppConstants.prefSendCrashReports
        case .dailyUsagePing:
            title = .SendDailyUsagePingSettingTitle
            message = String(format: .SendDailyUsagePingSettingMessage, MozillaName.shortName.rawValue)
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

        setupSettingDidChange(for: sendDataType)

        // We make sure to set this on initialization, in case the setting is turned off
        // in which case, we would to make sure that users are opted out of experiments
        Experiments.setTelemetrySetting(prefs.boolForKey(prefKey) ?? true)
    }

    private func setupSettingDidChange(for sendDataType: SendDataType) {
        self.settingDidChange = { [weak self] value in
            if sendDataType != .crashReports {
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

    override var url: URL? {
        switch sendDataType {
        case .usageData:
            return SupportUtils.URLForTopic("adjust")
        case .technicalData:
            return SupportUtils.URLForTopic("mobile-technical-and-interaction-data")
        case .crashReports:
            return SupportUtils.URLForTopic("mobile-crash-reports")
        case .dailyUsagePing:
            return SupportUtils.URLForTopic("usage-ping-settings-mobile")
        }
    }

    override func onClick(_ navigationController: UINavigationController?) {
        settingsDelegate?.askedToOpen(url: url, withTitle: title)
    }
}
