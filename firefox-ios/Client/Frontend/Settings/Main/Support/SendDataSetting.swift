// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Glean
import Shared

final class SendDataSetting: BoolSetting {
    private let titleText: String
    private let subtitleText: String
    private let learnMoreText: String
    private let learnMoreURL: URL?
    private let a11yId: String?
    private let learnMoreA11yId: String?
    private let defaultValue: Bool?
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
        self.defaultValue = defaultValue
        self.titleText = titleText
        self.subtitleText = subtitleText
        self.learnMoreText = learnMoreText
        self.learnMoreURL = learnMoreURL
        self.a11yId = a11yId
        self.learnMoreA11yId = learnMoreA11yId
        self.settingsDelegate = settingsDelegate
        self.featureFlagName = featureFlagName
        super.init(prefs: prefs,
                   defaultValue: defaultValue,
                   attributedTitleText: NSAttributedString(string: titleText))

        if isStudiesCase {
            let sendUsageDataPref = prefs?.boolForKey(AppConstants.prefSendUsageData) ?? true
            // Special Case (EXP-4780) disable studies if usage data is disabled
            updateSetting(for: sendUsageDataPref)
        } else {
            // We make sure to set this on initialization, in case the setting is turned off
            // in which case, we would to make sure that users are opted out of experiments
            guard let key = prefKey else { return }
            Experiments.setTelemetrySetting(prefs?.boolForKey(key) ?? true)
        }
    }

    override func onConfigureCell(_ cell: UITableViewCell, theme: Theme) {
        guard let cell = cell as? ThemedLearnMoreTableViewCell else { return }

        cell.configure(
            title: titleText,
            subtitle: subtitleText,
            learnMoreText: learnMoreText,
            a11yId: learnMoreA11yId,
            theme: theme
        )

        control.configureSwitch(
            onTintColor: theme.colors.actionPrimary,
            isEnabled: enabled
        )

        displayBool(control.switchView)
        control.switchView.accessibilityLabel = "\(titleText), \(subtitleText)"
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
            self.settingsDelegate?.askedToOpen(url: url, withTitle: NSAttributedString(string: self.titleText))
        }
    }

    func updateSetting(for isUsageEnabled: Bool) {
        guard !isUsageEnabled else {
            // Note: switch should be enabled only when telemetry usage is enabled
            control.setSwitchTappable(to: true)
            // We make sure to set this on initialization, in case the setting is turned off
            // in which case, we would to make sure that users are opted out of experiments
            Experiments.setStudiesSetting(prefs?.boolForKey(AppConstants.prefStudiesToggle) ?? true)
            return
        }

        // Special Case (EXP-4780) disable Studies if usage data is disabled
        control.setSwitchTappable(to: false)
        control.toggleSwitch(to: false)
        writeBool(control.switchView)
        Experiments.setStudiesSetting(false)
    }
}
