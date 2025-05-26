// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Shared

/// A view controller that manages the hidden Firefox Suggest debug settings.
final class FeatureFlagsDebugViewController: SettingsTableViewController, FeatureFlaggable {
    init(profile: Profile, windowUUID: WindowUUID) {
        super.init(style: .grouped, windowUUID: windowUUID)
        self.profile = profile
        self.title = "Feature Flags"
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func generateSettings() -> [SettingSection] {
        return [generateFeatureFlagToggleSettings(), generateFeatureFlagList()]
    }

    private func generateFeatureFlagToggleSettings() -> SettingSection {
        // For better code readability and parsability in-app, please keep in alphabetical order by title
        return SettingSection(
            title: nil,
            children: [
                FeatureFlagsBoolSetting(
                    with: .addressBarMenu,
                    titleText: format(string: "Enable New AddressBar Menu"),
                    statusText: format(string: "Toggle to show the new address bar menu")
                ) { [weak self] _ in
                    self?.reloadView()
                },
                FeatureFlagsBoolSetting(
                    with: .appearanceMenu,
                    titleText: format(string: "Appearance Menu"),
                    statusText: format(string: "Toggle to show the new apperance menu")
                ) { [weak self] _ in
                    self?.reloadView()
                },
                FeatureFlagsBoolSetting(
                    with: .bookmarksRefactor,
                    titleText: format(string: "Bookmarks Redesign"),
                    statusText: format(string: "Toggle to use the bookmarks redesign")
                ) { [weak self] _ in
                    guard let self else { return }
                    self.reloadView()
                    let isBookmarksRefactorEnabled = self.featureFlags.isFeatureEnabled(.bookmarksRefactor,
                                                                                        checking: .buildOnly)
                    self.profile?.prefs.setBool(isBookmarksRefactorEnabled, forKey: PrefsKeys.IsBookmarksRefactorEnabled)
                },
                FeatureFlagsBoolSetting(
                    with: .searchEngineConsolidation,
                    titleText: format(string: "Consolidated Search"),
                    statusText: format(string: "Toggle to use Consolidated Search")
                ) { [weak self] _ in
                    self?.reloadView()
                },
                FeatureFlagsBoolSetting(
                    with: .deeplinkOptimizationRefactor,
                    titleText: format(string: "Deeplink Optimization Refactor"),
                    statusText: format(string: "Toggle to enable deeplink optimization refactor")
                ) { [weak self] _ in
                    self?.reloadView()
                },
                FeatureFlagsBoolSetting(
                    with: .downloadLiveActivities,
                    titleText: format(string: "Download Live Activities"),
                    statusText: format(string: "Toggle to enable download live activities")
                ) { [weak self] _ in
                    self?.reloadView()
                },
                FeatureFlagsBoolSetting(
                    with: .trackingProtectionRefactor,
                    titleText: format(string: "Enhanced Tracking Protection"),
                    statusText: format(string: "Toggle to use enhanced tracking protection")
                ) { [weak self] _ in
                    self?.reloadView()
                },
                FeatureFlagsBoolSetting(
                    with: .feltPrivacyFeltDeletion,
                    titleText: format(string: "Felt Privacy Deletion"),
                    statusText: format(string: "Toggle to enable felt privacy deletion")
                ) { [weak self] _ in
                    self?.reloadView()
                },
                FeatureFlagsBoolSetting(
                    with: .feltPrivacySimplifiedUI,
                    titleText: format(string: "Felt Privacy UI"),
                    statusText: format(string: "Toggle to enable felt privacy UI")
                ) { [weak self] _ in
                    self?.reloadView()
                },
                FeatureFlagsBoolSetting(
                    with: .hntContentFeedRefresh,
                    titleText: format(string: "Homepage Content Feed Refresh"),
                    statusText: format(string: "Toggle to enable the content feed refresh")
                ) { [weak self] _ in
                    self?.reloadView()
                },
                FeatureFlagsBoolSetting(
                    with: .homepageRebuild,
                    titleText: format(string: "Homepage Rebuild"),
                    statusText: format(string: "Toggle to use the homepage rebuild")
                ) { [weak self] _ in
                    self?.reloadView()
                },
                FeatureFlagsBoolSetting(
                    with: .loginsVerificationEnabled,
                    titleText: format(string: "Logins Verification"),
                    statusText: format(string: "Toggle to enable logins verification")
                ) { [weak self] _ in
                    self?.reloadView()
                },
                FeatureFlagsBoolSetting(
                    with: .menuRefactor,
                    titleText: format(string: "Menu Redesign"),
                    statusText: format(string: "Toggle to use the menu redesign")
                ) { [weak self] _ in
                    self?.reloadView()
                },
                FeatureFlagsBoolSetting(
                    with: .microsurvey,
                    titleText: format(string: "Microsurvey"),
                    statusText: format(string: "Toggle to reset microsurvey expiration")
                ) { [weak self] _ in
                    UserDefaults.standard.set(nil, forKey: "\(GleanPlumbMessageStore.rootKey)\("homepage-microsurvey-message")")
                    self?.reloadView()
                },
                FeatureFlagsBoolSetting(
                    with: .nativeErrorPage,
                    titleText: format(string: "Native Error Page"),
                    statusText: format(string: "Toggle to display natively created error pages")
                ) { [weak self] _ in
                    self?.reloadView()
                },
                FeatureFlagsBoolSetting(
                    with: .noInternetConnectionErrorPage,
                    titleText: format(string: "NIC Native Error Page"),
                    statusText: format(string: "Toggle to display natively created no internet connection error page")
                ) { [weak self] _ in
                    self?.reloadView()
                },
                FeatureFlagsBoolSetting(
                    with: .pdfRefactor,
                    titleText: format(string: "PDF Refactor"),
                    statusText: format(string: "Toggle to enable PDF Refactor feature")
                ) { [weak self] _ in
                    self?.reloadView()
                },
                FeatureFlagsBoolSetting(
                    with: .useRustKeychain,
                    titleText: format(string: "Rust Keychain"),
                    statusText: format(string: "Toggle to enable rust keychain")
                ) { [weak self] _ in
                    self?.reloadView()
                },
                FeatureFlagsBoolSetting(
                    with: .sentFromFirefox,
                    titleText: format(string: "Sent from Firefox"),
                    statusText: format(string: "Toggle to enable Sent from Firefox to append text to WhatsApp shares")
                ) { [weak self] _ in
                    self?.reloadView()
                },
                FeatureFlagsBoolSetting(
                    with: .tabTrayUIExperiments,
                    titleText: format(string: "Tab Tray UI Experiment"),
                    statusText: format(string: "Toggle to use the new tab tray UI")
                ) { [weak self] _ in
                    self?.reloadView()
                },
                FeatureFlagsBoolSetting(
                    with: .tabAnimation,
                    titleText: format(string: "Tab Tray Animation"),
                    statusText: format(string: "Toggle to use the new tab tray animation when new tab experiment is enabled")
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
                    with: .hntTopSitesVisualRefresh,
                    titleText: format(string: "Top Sites Visual Refresh"),
                    statusText: format(string: "Toggle to enable the top sites visual refresh")
                ) { [weak self] _ in
                    self?.reloadView()
                },
                FeatureFlagsBoolSetting(
                    with: .unifiedAds,
                    titleText: format(string: "Unified Ads"),
                    statusText: format(string: "Toggle to use unified ads API")
                ) { [weak self] _ in
                    self?.reloadView()
                },
                FeatureFlagsBoolSetting(
                    with: .unifiedSearch,
                    titleText: format(string: "Unified Search"),
                    statusText: format(string: "Toggle to use unified search within the new toolbar")
                ) { [weak self] _ in
                    self?.reloadView()
                },
                FeatureFlagsBoolSetting(
                    with: .updatedPasswordManager,
                    titleText: format(string: "Updated Password Manager"),
                    statusText: format(string: "Toggle to enable the updated password manager")
                ) { [weak self] _ in
                    self?.reloadView()
                },
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
