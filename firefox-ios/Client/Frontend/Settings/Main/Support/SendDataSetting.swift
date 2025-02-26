// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Glean
import Shared

final class SendDataSetting: Setting, FeatureFlaggable {
    private let prefKey: String?
    private let prefs: Prefs?
    private let titleText: String
    private let subtitleText: String
    private let learnMoreText: String
    private let learnMoreURL: URL?
    private let a11yId: String?
    private let defaultValue: Bool?
    private let featureFlagName: NimbusFeatureFlagID?

    private weak var settingsDelegate: SupportSettingsDelegate?
    var shouldSendData: ((Bool) -> Void)?

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
        settingsDelegate: SupportSettingsDelegate?,
        featureFlagName: NimbusFeatureFlagID? = nil,
        enabled: Bool = true,
        isStudiesCase: Bool = false
    ) {
        self.prefs = prefs
        self.prefKey = prefKey
        self.defaultValue = defaultValue
        self.titleText = titleText
        self.subtitleText = subtitleText
        self.learnMoreText = learnMoreText
        self.learnMoreURL = learnMoreURL
        self.a11yId = a11yId
        self.settingsDelegate = settingsDelegate
        self.featureFlagName = featureFlagName
        super.init(title: NSAttributedString(string: titleText), enabled: enabled)

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

    public lazy var control: PaddedSwitch = {
        let control = PaddedSwitch()
        control.switchView.accessibilityIdentifier = prefKey
        control.switchView.addTarget(self, action: #selector(switchValueChanged), for: .valueChanged)
        return control
    }()

    override func onConfigureCell(_ cell: UITableViewCell, theme: Theme) {
        guard let cell = cell as? ThemedLearnMoreTableViewCell else { return }

        cell.configure(
            title: titleText,
            subtitle: subtitleText,
            learnMoreText: learnMoreText,
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

    @objc
    func switchValueChanged(_ control: UISwitch) {
        writeBool(control)
        shouldSendData?(control.isOn)
        if let featureFlagName = featureFlagName {
            TelemetryWrapper.recordEvent(category: .action,
                                         method: .change,
                                         object: .setting,
                                         extras: ["pref": featureFlagName.rawValue as Any,
                                                  "to": control.isOn])
        } else {
            TelemetryWrapper.recordEvent(category: .action,
                                         method: .change,
                                         object: .setting,
                                         extras: ["pref": prefKey as Any, "to": control.isOn])
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

    // These methods allow a subclass to control how the pref is saved
    func displayBool(_ control: UISwitch) {
        if let featureFlagName = featureFlagName {
            control.isOn = featureFlags.isFeatureEnabled(featureFlagName, checking: .userOnly)
        } else {
            guard let key = prefKey, let defaultValue = defaultValue else { return }
            control.isOn = prefs?.boolForKey(key) ?? defaultValue
        }
    }

    func writeBool(_ control: UISwitch) {
        if let featureFlagName = featureFlagName {
            featureFlags.set(feature: featureFlagName, to: control.isOn)
        } else {
            guard let key = prefKey else { return }
            prefs?.setBool(control.isOn, forKey: key)
        }
    }
}
