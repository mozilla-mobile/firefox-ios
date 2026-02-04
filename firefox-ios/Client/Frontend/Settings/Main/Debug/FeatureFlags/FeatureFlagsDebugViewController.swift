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
        return [
            generateFeatureFlagToggleSettings(),
            generateDefaultBrowserStatusDisplay(),
            generateFeatureFlagList()
        ]
    }

    // swiftlint:disable:next function_body_length
    private func generateFeatureFlagToggleSettings() -> SettingSection {
        // For better code readability and parsability in-app, please keep in alphabetical order by title
        var children: [Setting] =  [
            FeatureFlagsBoolSetting(
                with: .appearanceMenu,
                titleText: format(string: "Appearance Menu"),
                statusText: format(string: "Toggle to show the new apperance menu")
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
                with: .defaultZoomFeature,
                titleText: format(string: "Default zoom"),
                statusText: format(string: "Toggle to enable default zoom feature")
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
                with: .homepageSearchBar,
                titleText: format(string: "Homepage Search Bar"),
                statusText: format(string: "Toggle to enable homepage search bar for redesign")
            ) { [weak self] _ in
                self?.reloadView()
            },
            FeatureFlagsBoolSetting(
                with: .menuRefactor,
                titleText: format(string: "Menu Refactor"),
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
                with: .privacyNotice,
                titleText: format(string: "Privacy Notice"),
                statusText: format(string: "Toggle to enable the Privacy Notice homepage card")
            ) { [weak self] _ in
                self?.reloadView()
            },
            FeatureFlagsBoolSetting(
                with: .otherErrorPages,
                titleText: format(string: "Other Error Pages"),
                statusText: format(string: "Toggle to display natively created error pages for certificate and other errors")
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
                with: .toolbarRefactor,
                titleText: format(string: "Toolbar Redesign"),
                statusText: format(string: "Toggle to enable the toolbar redesign")
            ) { [weak self] _ in
                self?.reloadView()
            },
            FeatureFlagsBoolSetting(
                with: .toolbarTranslucencyRefactor,
                titleText: format(string: "Toolbar Translucency Refactor"),
                statusText: format(string: "Toggle to enable the toolbar translucency refactor")
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
                with: .unifiedSearch,
                titleText: format(string: "Unified Search"),
                statusText: format(string: "Toggle to use unified search within the new toolbar")
            ) { [weak self] _ in
                self?.reloadView()
            },
            FeatureFlagsBoolSetting(
                with: .voiceSearch,
                titleText: format(string: "Voice Search"),
                statusText: format(string: "Toggle to enable the Voice Search feature")
            ) { [weak self] _ in
                self?.reloadView()
            },
            FeatureFlagsBoolSetting(
                with: .webEngineIntegrationRefactor,
                titleText: format(string: "Web Engine Integration Refactor"),
                statusText: format(string: "Toggle to enable the use of WebEngine library")
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
        ]

        // Conditionally add the Apple Summarizer only if the compile time check for the FoundationModels is true
        // and the LLM is supported on the device.
        #if canImport(FoundationModels)
            if AppleIntelligenceUtil().isAppleIntelligenceAvailable {
                children.append(
                    FeatureFlagsBoolSetting(
                        with: .appleSummarizer,
                        titleText: format(string: "Apple Summarizer Feature"),
                        statusText: format(string: "Toggle to enable the apple summarizer feature")
                    ) { [weak self] _ in
                        self?.reloadView()
                    }
                )
            }
        #endif

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
