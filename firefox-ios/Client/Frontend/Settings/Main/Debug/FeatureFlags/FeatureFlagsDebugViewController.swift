// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Shared

/// A view controller that manages the hidden Firefox Suggest debug settings.
final class FeatureFlagsDebugViewController: SettingsTableViewController, LegacyFeatureFlaggable {
    init(profile: Profile, windowUUID: WindowUUID) {
        super.init(style: .grouped, windowUUID: windowUUID)
        self.profile = profile
        self.title = "Feature Flags"
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func generateSettings() -> [SettingSection] {
        return [
            generateFeatureFlagToggleSettings(),
            generateDefaultBrowserStatusDisplay(),
            generateFeatureFlagList()
        ]
    }

    // swiftlint:disable:next function_body_length
    private func generateFeatureFlagToggleSettings() -> SettingSection {
        // For better code readability and parsability in-app, please keep in alphabetical order by title
        let children: [Setting] =  [
            FeatureFlagsBoolSetting(
                with: .httpsUpgrade,
                titleText: format(string: "Automatic HTTPS upgrade"),
                statusText: format(string: "Toggle to enable automatic HTTPS upgrade.")
            ) { [weak self] _ in
                self?.reloadView()
            },
            FeatureFlagsBoolSetting(
                with: .adsClient,
                titleText: format(string: "Ads Client"),
                statusText: format(string: "Toggle to enable the rust ads client")
            ) { [weak self] _ in
                self?.reloadView()
            },
            FeatureFlagsBoolSetting(
                with: .aiKillSwitch,
                titleText: format(string: "Ai Kill Switch"),
                statusText: format(string: "Toggle Ai Kill Switch")
            ) { [weak self] _ in
                self?.reloadView()
            },
            FeatureFlagsBoolSetting(
                with: .appearanceMenu,
                titleText: format(string: "Appearance Menu"),
                statusText: format(string: "Toggle to show the new appearance menu")
            ) { [weak self] _ in
                self?.reloadView()
            },
            FeatureFlagsBoolSetting(
                with: .bookmarksSearchFeature,
                titleText: format(string: "Bookmarks Search"),
                statusText: format(string: "Toggle to enable bookmarks panel search feature")
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
                with: .homepageSearchBar,
                titleText: format(string: "Homepage Search Bar"),
                statusText: format(string: "Toggle to enable homepage search bar for redesign")
            ) { [weak self] _ in
                self?.reloadView()
            },
            FeatureFlagsBoolSetting(
                with: .homepageStoryCategories,
                titleText: format(string: "Homepage Story Categories"),
                statusText: format(string: "Toggle to enable homepage story categories")
            ) { [weak self] _ in
                self?.reloadView()
            },
            FeatureFlagsBoolSetting(
                with: .improvedAppStoreReviewTriggerFeature,
                titleText: format(string: "Improved App Store Review Trigger"),
                statusText: format(string: "Toggle to enable App Store Review Trigger feature.")
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
                with: .addressBarMenu,
                titleText: format(string: "New AddressBar Menu"),
                statusText: format(string: "Toggle to show the new address bar menu")
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
                with: .badCertDomainErrorPage,
                titleText: format(string: "Bad Cert Domain Native Error Page"),
                statusText: format(string: "Toggle to display the natively created bad cert domain error page")
            ) { [weak self] _ in
                self?.reloadView()
            },
            FeatureFlagsBoolSetting(
                with: .relayIntegration,
                titleText: format(string: "Relay Email Masks"),
                statusText: format(string: "Toggle to enable Relay mask feature")
            ) { [weak self] _ in
                self?.reloadView()
            },
            FeatureFlagsBoolSetting(
                with: .recentSearches,
                titleText: format(string: "Search - Recent"),
                statusText: format(string: "Toggle to enable the recent searches feature")
            ) { [weak self] _ in
                self?.reloadView()
            },
            FeatureFlagsBoolSetting(
                with: .trendingSearches,
                titleText: format(string: "Search - Trending"),
                statusText: format(string: "Toggle to enable the trending searches feature")
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
                with: .snapkitRemovalRefactor,
                titleText: format(string: "SnapKit Removal Refactor"),
                statusText: format(string: "Toggle to enable SnapKit removal refactor")
            ) { [weak self] _ in
                self?.reloadView()
            },
            FeatureFlagsBoolSetting(
                with: .summarizerLanguageExpansion,
                titleText: format(string: "Summarizer Language Expansion"),
                statusText: format(string: "Toggle to enable Summarizer language expansion feature")
            ) { [weak self] _ in
                self?.reloadView()
            },
            FeatureFlagsBoolSetting(
                with: .tabScrollRefactorFeature,
                titleText: format(string: "Tab scroll refactor"),
                statusText: format(string: "Toggle to enable tab scroll refactor feature")
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
                with: .tabTrayiPadUIExperiments,
                titleText: format(string: "Tab Tray iPad UI Experiment"),
                statusText: format(string: "Toggle to use the new tab tray UI on iPad")
            ) { [weak self] _ in
                self?.reloadView()
            },
            FeatureFlagsBoolSetting(
                with: .touFeature,
                titleText: format(string: "Terms of Use"),
                statusText: format(string: "Toggle to enable Terms of Use feature")
            ) { [weak self] _ in
                self?.reloadView()
            },
            FeatureFlagsBoolSetting(
                with: .translation,
                titleText: format(string: "Translations"),
                statusText: format(string: "Toggle to enable translations feature")
            ) { [weak self] _ in
                self?.reloadView()
            },
            FeatureFlagsBoolSetting(
                with: .translationLanguagePicker,
                titleText: format(string: "Translation Language Picker"),
                statusText: format(string: "Toggle to enable language picker for translations")
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
                with: .quickAnswers,
                titleText: format(string: "Quick Answers"),
                statusText: format(string: "Toggle to enable the Quick Answers feature")
            ) { [weak self] _ in
                self?.reloadView()
            },
            FeatureFlagsBoolSetting(
                with: .worldCupWidget,
                titleText: format(string: "World Cup Widget"),
                statusText: format(string: "Toggle to enable the World Cup widget feature on the Homepage")
            ) { [weak self] _ in
                self?.reloadView()
            },
            FeatureFlagsBoolSetting(
                with: .hostedSummarizer,
                titleText: format(string: "Hosted Summarizer Feature"),
                statusText: format(string: "Toggle to enable the hosted summarizer feature")
            ) { [weak self] _ in
                self?.reloadView()
            },
            FeatureFlagsBoolSetting(
                with: .summarizerAppAttestAuth,
                titleText: format(string: "Summarizer App Attest Auth Feature"),
                statusText: format(string: "Toggle to enable the app attest authentication for the summarizer feature")
            ) { [weak self] _ in
                self?.reloadView()
            },
            FeatureFlagsBoolSetting(
                with: .needsReloadRefactor,
                titleText: format(string: "Needs Reload Refactor"),
                statusText: format(string: "Toggle to enable the needs reload refactor")
            ) { [weak self] _ in
                self?.reloadView()
            },
            FeatureFlagsBoolSetting(
                with: .summarizerPermissiveGuardrails,
                titleText: format(string: "Summarizer Permissive Guardrails Feature"),
                statusText: format(string: "Toggle to enable the permissive guardrails for the summarizer feature")
            ) { [weak self] _ in
                self?.reloadView()
            },
        ]

        return SettingSection(
            title: nil,
            children: children
        )
    }

    private func generateDefaultBrowserStatusDisplay() -> SettingSection {
        return SettingSection(
            title: NSAttributedString(string: "Default Browser Status"),
            children: [Setting(
                title: format(string: "isDefaultBrowser: \(DefaultBrowserUtility().isDefaultBrowser)")
            )]
        )
    }

    private func generateFeatureFlagList() -> SettingSection {
        let flags = FeatureFlagID.allCases
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
