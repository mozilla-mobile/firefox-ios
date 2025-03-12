// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Glean
import Shared

final class SendDataSetting: BoolSetting {
    private let learnMoreText: String
    private let learnMoreURL: URL?
    private let a11yId: String?
    private let learnMoreA11yId: String?
    private let featureFlagName: NimbusFeatureFlagID?

    private weak var settingsDelegate: SupportSettingsDelegate?

    override var url: URL? { return learnMoreURL }
    override var accessibilityIdentifier: String? { return a11yId }

    init(
        prefs: Prefs?,
        prefKey: String? = nil,
        defaultValue: Bool?,
        titleText: String,
        subtitleText: String,
        learnMoreText: String,
        learnMoreURL: URL?,
        a11yId: String?,
        learnMoreA11yId: String?,
        settingsDelegate: SupportSettingsDelegate?,
        featureFlagName: NimbusFeatureFlagID? = nil,
        enabled: Bool = true,
        isStudiesCase: Bool = false
    ) {
        self.learnMoreText = learnMoreText
        self.learnMoreURL = learnMoreURL
        self.a11yId = a11yId
        self.learnMoreA11yId = learnMoreA11yId
        self.settingsDelegate = settingsDelegate
        self.featureFlagName = featureFlagName
        super.init(prefs: prefs,
                   prefKey: prefKey,
                   defaultValue: defaultValue,
                   attributedTitleText: NSAttributedString(string: titleText),
                   attributedStatusText: NSAttributedString(string: subtitleText))

        if isStudiesCase {
            let sendUsageDataPref = prefs?.boolForKey(AppConstants.prefSendUsageData) ?? true
            // Special Case (EXP-4780, FXIOS-10534) disable studies if usage data is disabled
            // and studies should be toggled back on after re-enabling Telemetry
            self.enabled = sendUsageDataPref
        } else {
            // We make sure to set this on initialization, in case the setting is turned off
            // in which case, we would to make sure that users are opted out of experiments
            guard let key = prefKey else { return }
            Experiments.setTelemetrySetting(prefs?.boolForKey(key) ?? true)
        }
    }

    override func onConfigureCell(_ cell: UITableViewCell, theme: Theme) {
        guard let cell = cell as? ThemedLearnMoreTableViewCell else { return }
        guard let title = title?.string, let subtitle = status?.string else { return }

        cell.configure(
            title: title,
            subtitle: subtitle,
            learnMoreText: learnMoreText,
            a11yId: learnMoreA11yId,
            theme: theme
        )

        control.configureSwitch(
            onTintColor: theme.colors.actionPrimary,
            isEnabled: enabled
        )

        displayBool(control.switchView)
        control.switchView.accessibilityLabel = "\(title), \(subtitle)"
        if let accessibilityIdentifier {
            cell.setAccessibilities(traits: .none, identifier: accessibilityIdentifier)
        }

        cell.accessoryView = control
        cell.selectionStyle = .none

        if !enabled {
            cell.subviews.forEach { $0.alpha = 0.5 }
        }

        cell.learnMoreDidTap = { [weak self] in
            guard let self else { return }
            self.settingsDelegate?.askedToOpen(url: url, withTitle: NSAttributedString(string: title))
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
}
