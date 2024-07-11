// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation

/// A view controller that manages the hidden Firefox Suggest debug settings.
final class FeatureFlagsDebugViewController: SettingsTableViewController, FeatureFlaggable {
    init(windowUUID: WindowUUID) {
        super.init(style: .grouped, windowUUID: windowUUID)
        self.title = "Feature Flags"
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func generateSettings() -> [SettingSection] {
        return [generateFeatureFlagToggleSettings(), generateFeatureFlagList()]
    }

    private func generateFeatureFlagToggleSettings() -> SettingSection {
        let theme = themeManager.getCurrentTheme(for: windowUUID)
        let microsurveySetting = FeatureFlagsBoolSetting(
            with: .microsurvey,
            titleText: NSAttributedString(
                string: "Enable Microsurvey",
                attributes: [NSAttributedString.Key.foregroundColor: theme.colors.textPrimary]),
            statusText: NSAttributedString(
                string: "Toggle to reset microsurvey expiration",
                attributes: [NSAttributedString.Key.foregroundColor: theme.colors.textPrimary])
        ) { [weak self] _ in
            UserDefaults.standard.set(nil, forKey: "\(GleanPlumbMessageStore.rootKey)\("homepage-microsurvey-message")")
            guard let self else { return }
            self.reloadView()
        }
        return SettingSection(title: nil, children: [microsurveySetting])
    }

    private func generateFeatureFlagList() -> SettingSection {
        let theme = themeManager.getCurrentTheme(for: windowUUID)
        let flags = NimbusFeatureFlagID.allCases
        let settingsList = flags.compactMap { flagID in
            return Setting(title: NSAttributedString(
                string: "\(flagID): \(featureFlags.isFeatureEnabled(flagID, checking: .buildOnly))",
                attributes: [NSAttributedString.Key.foregroundColor: theme.colors.textPrimary])
            )
        }
        return SettingSection(
            title: NSAttributedString(string: "Build only status"),
            children: settingsList
        )
    }

    private func reloadView() {
        self.settings = self.generateSettings()
        self.tableView.reloadData()
    }
}
