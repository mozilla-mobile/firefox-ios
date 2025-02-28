// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Shared

class StudiesToggleSetting: BoolSetting {
    private weak var settingsDelegate: SupportSettingsDelegate?

    init(prefs: Prefs,
         delegate: SettingsDelegate?,
         theme: Theme,
         settingsDelegate: SupportSettingsDelegate?,
         title: String,
         message: String,
         linkedText: String) {
        let statusText = NSMutableAttributedString()
        statusText.append(
            NSAttributedString(
                string: message,
                attributes: [NSAttributedString.Key.foregroundColor: theme.colors.textSecondary]
            )
        )
        statusText.append(NSAttributedString(string: "\n"))
        statusText.append(
            NSAttributedString(
                string: linkedText,
                attributes: [NSAttributedString.Key.foregroundColor: theme.colors.actionPrimary]
            )
        )

        self.settingsDelegate = settingsDelegate

        super.init(
            prefs: prefs,
            prefKey: AppConstants.prefStudiesToggle,
            defaultValue: true,
            attributedTitleText: NSAttributedString(string: title),
            attributedStatusText: statusText,
            settingDidChange: {
                Experiments.setStudiesSetting($0)
            }
        )

        setupSettingDidChange()

        let sendUsageDataPref = prefs.boolForKey(AppConstants.prefSendUsageData) ?? true

        // Special Case (EXP-4780, FXIOS-10534) disable studies if usage data is disabled
        // and studies should be toggled back on after re-enabling Telemetry
        self.enabled = sendUsageDataPref
    }

    private func setupSettingDidChange() {
        self.settingDidChange = {
            Experiments.setStudiesSetting($0)
        }
    }

    func updateSetting(for isUsageEnabled: Bool) {
        self.enabled = isUsageEnabled
        // We make sure to set this on initialization, in case the setting is turned off
        // in which case, we would to make sure that users are opted out of experiments
        // Note: Switch should be enabled only when telemetry usage is enabled
        updateControlState(isEnabled: isUsageEnabled)

        // Set experiments study setting based on usage enabled state
        // Special Case (EXP-4780, FXIOS-10534) disable Studies if usage data is disabled
        // and studies should be toggled back on after re-enabling Telemetry
        let studiesEnabled = isUsageEnabled && (prefs?.boolForKey(AppConstants.prefStudiesToggle) ?? true)
        Experiments.setStudiesSetting(studiesEnabled)
    }

    private func updateControlState(isEnabled: Bool) {
        control.setSwitchTappable(to: isEnabled)
        control.toggleSwitch(to: isEnabled)
        writeBool(control.switchView)
    }

    override var accessibilityIdentifier: String? {
        return AccessibilityIdentifiers.Settings.StudiesToggle.title
    }

    override var url: URL? {
        return SupportUtils.URLForTopic("ios-studies")
    }

    override func onClick(_ navigationController: UINavigationController?) {
        settingsDelegate?.askedToOpen(url: url, withTitle: title)
    }
}
