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
        return SettingSection(
            title: nil,
            children: [
                FeatureFlagsBoolSetting(
                    with: .bookmarksRefactor,
                    titleText: format(string: "Enable Bookmarks Redesign"),
                    statusText: format(string: "Toggle to use the new bookmarks design")
                ) { [weak self] _ in
                    self?.reloadView()
                },
                FeatureFlagsBoolSetting(
                    with: .closeRemoteTabs,
                    titleText: format(string: "Enable Close Remote Tabs"),
                    statusText: format(string: "Toggle to enable closing tabs remotely feature")
                ) { [weak self] _ in
                    self?.reloadView()
                },
                FeatureFlagsBoolSetting(
                    with: .microsurvey,
                    titleText: format(string: "Enable Microsurvey"),
                    statusText: format(string: "Toggle to reset microsurvey expiration")
                ) { [weak self] _ in
                    UserDefaults.standard.set(nil, forKey: "\(GleanPlumbMessageStore.rootKey)\("homepage-microsurvey-message")")
                    self?.reloadView()
                },
                FeatureFlagsBoolSetting(
                    with: .homepageRebuild,
                    titleText: format(string: "Enable New Homepage"),
                    statusText: format(string: "Toggle to use the new homepage")
                ) { [weak self] _ in
                    self?.reloadView()
                },
                FeatureFlagsBoolSetting(
                    with: .menuRefactor,
                    titleText: format(string: "Enable New Menu"),
                    statusText: format(string: "Toggle to use the new menu")
                ) { [weak self] _ in
                    self?.reloadView()
                },
                FeatureFlagsBoolSetting(
                    with: .trackingProtectionRefactor,
                    titleText: format(string: "Enable New Tracking Protection"),
                    statusText: format(string: "Toggle to use the new tracking protection")
                ) { [weak self] _ in
                    self?.reloadView()
                },
                FeatureFlagsBoolSetting(
                    with: .nativeErrorPage,
                    titleText: format(string: "Enable Native Error Page"),
                    statusText: format(string: "Toggle to display natively created error pages")
                ) { [weak self] _ in
                    self?.reloadView()
                },
                FeatureFlagsBoolSetting(
                    with: .noInternetConnectionErrorPage,
                    titleText: format(string: "Enable NIC Native Error Page"),
                    statusText: format(string: "Toggle to display natively created no internet connection error page")
                ) { [weak self] _ in
                    self?.reloadView()
                },
                FeatureFlagsBoolSetting(
                    with: .toolbarRefactor,
                    titleText: format(string: "Toolbar Redesign"),
                    statusText: format(string: "Toggle to enable the toolbar redesign")
                ) { [weak self] _ in
                    self?.reloadView()
                },
                FeatureFlagsBoolSetting(
                    with: .unifiedAds,
                    titleText: format(string: "Enable Unified Ads"),
                    statusText: format(string: "Toggle to use unified ads API")
                ) { [weak self] _ in
                    self?.reloadView()
                },
                FeatureFlagsBoolSetting(
                    with: .unifiedSearch,
                    titleText: format(string: "Enable Unified Search"),
                    statusText: format(string: "Toggle to use unified search within the new toolbar")
                ) { [weak self] _ in
                    self?.reloadView()
                },
                FeatureFlagsBoolSetting(
                    with: .passwordGenerator,
                    titleText: format(string: "Enable Password Generator"),
                    statusText: format(string: "Toggle to enable password generator feature")
                ) { [weak self] _ in
                    self?.reloadView()
                },
                FeatureFlagsBoolSetting(
                    with: .sentFromFirefox,
                    titleText: format(string: "Enable Sent from Firefox"),
                    statusText: format(string: "Toggle to enable Sent from Firefox to append text to WhatsApp shares")
                ) { [weak self] _ in
                    self?.reloadView()
                }
            ]
        )
    }

    private func generateFeatureFlagList() -> SettingSection {
        let flags = NimbusFeatureFlagID.allCases
        let settingsList = flags.compactMap { flagID in
            return Setting(title: format(string: "\(flagID): \(featureFlags.isFeatureEnabled(flagID, checking: .buildOnly))"))
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

    private func format(string: String) -> NSAttributedString {
        let theme = themeManager.getCurrentTheme(for: windowUUID)
        return NSAttributedString(
            string: string,
            attributes: [NSAttributedString.Key.foregroundColor: theme.colors.textPrimary]
        )
    }
}
