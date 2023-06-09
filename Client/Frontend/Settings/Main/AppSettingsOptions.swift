// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Shared
import Account
import LocalAuthentication

// Opens the on-boarding screen again
class ShowIntroductionSetting: Setting {
    let profile: Profile

    override var accessibilityIdentifier: String? { return "ShowTour" }

    init(settings: SettingsTableViewController) {
        self.profile = settings.profile
        let attributes = [NSAttributedString.Key.foregroundColor: settings.themeManager.currentTheme.colors.textPrimary]
        super.init(title: NSAttributedString(string: .AppSettingsShowTour,
                                             attributes: attributes))
    }

    override func onClick(_ navigationController: UINavigationController?) {
        navigationController?.dismiss(animated: true, completion: {
            NotificationCenter.default.post(name: .PresentIntroView, object: self)

            TelemetryWrapper.recordEvent(
                category: .action,
                method: .tap,
                object: .settingsMenuShowTour
            )
        })
    }
}

class SendFeedbackSetting: Setting {
    override var title: NSAttributedString? {
        return NSAttributedString(string: .AppSettingsSendFeedback, attributes: [NSAttributedString.Key.foregroundColor: theme.colors.textPrimary])
    }

    override var url: URL? {
        return URL(string: "https://connect.mozilla.org/")
    }

    override func onClick(_ navigationController: UINavigationController?) {
        setUpAndPushSettingsContentViewController(navigationController, self.url)
    }
}

class SendAnonymousUsageDataSetting: BoolSetting {
    init(prefs: Prefs, delegate: SettingsDelegate?, theme: Theme) {
        let statusText = NSMutableAttributedString()
        statusText.append(NSAttributedString(string: .SendUsageSettingMessage, attributes: [NSAttributedString.Key.foregroundColor: theme.colors.textSecondary]))
        statusText.append(NSAttributedString(string: " "))
        statusText.append(NSAttributedString(string: .SendUsageSettingLink, attributes: [NSAttributedString.Key.foregroundColor: theme.colors.actionPrimary]))

        super.init(
            prefs: prefs,
            prefKey: AppConstants.prefSendUsageData,
            defaultValue: true,
            attributedTitleText: NSAttributedString(string: .SendUsageSettingTitle),
            attributedStatusText: statusText,
            settingDidChange: {
                AdjustHelper.setEnabled($0)
                DefaultGleanWrapper.shared.setUpload(isEnabled: $0)
                Experiments.setTelemetrySetting($0)
            }
        )
        // We make sure to set this on initialization, in case the setting is turned off
        // in which case, we would to make sure that users are opted out of experiments
        Experiments.setTelemetrySetting(prefs.boolForKey(AppConstants.prefSendUsageData) ?? true)
    }

    override var accessibilityIdentifier: String? { return "SendAnonymousUsageData" }

    override var url: URL? {
        return SupportUtils.URLForTopic("adjust")
    }

    override func onClick(_ navigationController: UINavigationController?) {
        setUpAndPushSettingsContentViewController(navigationController, self.url)
    }
}

class StudiesToggleSetting: BoolSetting {
    init(prefs: Prefs, delegate: SettingsDelegate?, theme: Theme) {
        let statusText = NSMutableAttributedString()
        statusText.append(NSAttributedString(string: .SettingsStudiesToggleMessage, attributes: [NSAttributedString.Key.foregroundColor: theme.colors.textSecondary]))
        statusText.append(NSAttributedString(string: " "))
        statusText.append(NSAttributedString(string: .SettingsStudiesToggleLink, attributes: [NSAttributedString.Key.foregroundColor: theme.colors.actionPrimary]))

        super.init(
            prefs: prefs,
            prefKey: AppConstants.prefStudiesToggle,
            defaultValue: true,
            attributedTitleText: NSAttributedString(string: .SettingsStudiesToggleTitle),
            attributedStatusText: statusText,
            settingDidChange: {
                Experiments.setStudiesSetting($0)
            }
        )
        // We make sure to set this on initialization, in case the setting is turned off
        // in which case, we would to make sure that users are opted out of experiments
        Experiments.setStudiesSetting(prefs.boolForKey(AppConstants.prefStudiesToggle) ?? true)
    }

    override var accessibilityIdentifier: String? { return "StudiesToggle" }

    override var url: URL? {
        return SupportUtils.URLForTopic("ios-studies")
    }

    override func onClick(_ navigationController: UINavigationController?) {
        setUpAndPushSettingsContentViewController(navigationController, self.url)
    }
}

// Opens the SUMO page in a new tab
class OpenSupportPageSetting: Setting {
    init(delegate: SettingsDelegate?, theme: Theme) {
        super.init(title: NSAttributedString(string: .AppSettingsHelp, attributes: [NSAttributedString.Key.foregroundColor: theme.colors.textPrimary]),
                   delegate: delegate)
    }

    override func onClick(_ navigationController: UINavigationController?) {
        navigationController?.dismiss(animated: true) {
            if let url = URL(string: "https://support.mozilla.org/products/ios") {
                self.delegate?.settingsOpenURLInNewTab(url)
            }
        }
    }
}
