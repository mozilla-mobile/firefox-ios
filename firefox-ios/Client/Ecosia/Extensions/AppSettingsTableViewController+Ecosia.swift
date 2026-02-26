// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit
import Shared
import Ecosia

extension AppSettingsTableViewController {

    func getEcosiaSettingsSectionsShowingDebug(_ isDebugSectionEnabled: Bool) -> [SettingSection] {
        var sections = [
            getSearchSection(),
            getCustomizationSection(),
            getEcosiaGeneralSection(),
            getEcosiaPrivacySection(),
            getEcosiaSupportSection(),
            getEcosiaAboutSection()
        ]

        if User.shared.shouldShowDefaultBrowserSettingNudgeCard {
            sections.insert(getEcosiaDefaultBrowserSection(), at: 0)
        }

        if isDebugSectionEnabled {
            sections.append(getEcosiaDebugSupportSection())
            sections.append(getEcosiaDebugUnleashSection())
            sections.append(getEcosiaDebugAccountsSection())
        }

        return sections
    }
}

extension AppSettingsTableViewController {

    // We need this section as a placeholder for the default browser nudge card.
    private func getEcosiaDefaultBrowserSection() -> SettingSection {
        .init(children: [DefaultBrowserSetting(theme: themeManager.getCurrentTheme(for: windowUUID))])
    }

    private func getSearchSection() -> SettingSection {
        guard let profile else {
            return .init(title: .init(string: .localized(.search)), children: [
                EcosiaDefaultBrowserSettings(),
                SearchAreaSetting(settings: self),
                SafeSearchSettings(settings: self)
            ])
        }
        let theme = themeManager.getCurrentTheme(for: windowUUID)
        let settings: [Setting] = [
            EcosiaDefaultBrowserSettings(),
            SearchAreaSetting(settings: self),
            SafeSearchSettings(settings: self),
            AutoCompleteSettings(prefs: profile.prefs, theme: theme),
            PersonalSearchSettings(prefs: profile.prefs, theme: theme),
            AIOverviewsSearchSettings(prefs: profile.prefs, theme: theme)
        ]

        return .init(title: .init(string: .localized(.search)),
                     children: settings)
    }

    private func getCustomizationSection() -> SettingSection {
        var customizationSettings: [Setting] = [
            HomepageSettings(settings: self, settingsDelegate: settingsDelegate)
        ]

        /* Ecosia: inactiveTabs / TabsSetting removed in Firefox upgrade; re-add if Nimbus adds flag
        let inactiveTabsAreBuildActive = featureFlags.isFeatureEnabled(.inactiveTabs, checking: .buildOnly)
        if inactiveTabsAreBuildActive {
            customizationSettings.append(TabsSetting(theme: ..., settingsDelegate: parentCoordinator))
        }
        */

        if isSearchBarLocationFeatureEnabled, let profile {
            customizationSettings.append(SearchBarSetting(settings: self, profile: profile, settingsDelegate: parentCoordinator))
        }

        return .init(title: .init(string: .localized(.customization)),
                     children: customizationSettings)
    }

    private func getEcosiaGeneralSection() -> SettingSection {
        guard let profile else {
            return .init(title: .init(string: .SettingsGeneralSectionTitle),
                         children: [
                            ThemeSetting(settings: self, settingsDelegate: parentCoordinator),
                            SiriPageSetting(settings: self, settingsDelegate: parentCoordinator)
                         ])
        }
        let theme = themeManager.getCurrentTheme(for: windowUUID)
        /* Ecosia: OpenWithSetting expects BrowsingSettingsDelegate; parentCoordinator is SettingsFlowDelegate so pass nil */
        let generalSettings: [Setting] = [
            OpenWithSetting(settings: self, settingsDelegate: nil),
            ThemeSetting(settings: self, settingsDelegate: parentCoordinator),
            SiriPageSetting(settings: self, settingsDelegate: parentCoordinator),
            BlockPopupSetting(prefs: profile.prefs),
            NoImageModeSetting(profile: profile),
            BoolSetting(
                prefs: profile.prefs,
                theme: theme,
                prefKey: "showClipboardBar",
                defaultValue: false,
                titleText: .SettingsOfferClipboardBarTitle,
                statusText: String(format: .SettingsOfferClipboardBarStatus, AppName.shortName.rawValue)
            ),
            BoolSetting(
                prefs: profile.prefs,
                theme: theme,
                prefKey: PrefsKeys.ContextMenuShowLinkPreviews,
                defaultValue: true,
                titleText: .SettingsShowLinkPreviewsTitle,
                statusText: .SettingsShowLinkPreviewsStatus
            )
        ]

        return .init(title: .init(string: .SettingsGeneralSectionTitle),
                     children: generalSettings)
    }

    private func getEcosiaSupportSection() -> SettingSection {
        let helpCenterSetting = HelpCenterSetting()
        let sendFeedbackSetting = EcosiaSendFeedbackSetting(settings: self)

        return .init(title: NSAttributedString(string: .AppSettingsSupport),
                     children: [helpCenterSetting, sendFeedbackSetting])
    }

    private func getEcosiaPrivacySection() -> SettingSection {
        let theme = themeManager.getCurrentTheme(for: windowUUID)
        var privacySettings: [Setting] = [
            PasswordManagerSetting(settings: self, settingsDelegate: parentCoordinator),
            ClearPrivateDataSetting(settings: self, settingsDelegate: parentCoordinator),
            ContentBlockerSetting(settings: self, settingsDelegate: parentCoordinator),
            EcosiaPrivacyPolicySetting(settings: self),
            EcosiaTermsSetting(settings: self)
        ]
        if let profile {
            privacySettings.insert(EcosiaSendAnonymousUsageDataSetting(prefs: profile.prefs, theme: theme), at: 2)
            privacySettings.insert(BoolSetting(prefs: profile.prefs,
                                               theme: theme,
                                               prefKey: PrefsKeys.Settings.closePrivateTabs,
                                               // Ecosia: Default value is different from Firefox
                                               defaultValue: PrefsKeysDefaultValues.Settings.closePrivateTabs,
                                               titleText: .AppSettingsClosePrivateTabsTitle,
                                               statusText: .AppSettingsClosePrivateTabsDescription), at: 3)
        }

        return .init(title: NSAttributedString(string: .AppSettingsPrivacyTitle),
                     children: privacySettings)
    }

    private func getEcosiaAboutSection() -> SettingSection {
        let aboutSettings = [
            AppStoreReviewSetting(settingsDelegate: parentCoordinator),
            VersionSetting(settingsDelegate: self),
            LicenseAndAcknowledgementsSetting(settingsDelegate: parentCoordinator),
        ]

        return .init(title: NSAttributedString(string: .AppSettingsAbout),
                     children: aboutSettings)
    }

    private func getEcosiaDebugSupportSection() -> SettingSection {
        /* Ecosia: FasterInactiveTabs removed in Firefox upgrade; re-add if type is restored */
        var hiddenDebugSettings: [Setting] = [
            ExportBrowserDataSetting(settings: self),
            ForceCrashSetting(settings: self),
            PushBackInstallation(settings: self),
            OpenFiftyTabsDebugOption(settings: self, settingsDelegate: self),
            ToggleDefaultBrowserPromo(settings: self),
            ToggleImpactIntro(settings: self),
            ShowTour(settings: self, windowUUID: windowUUID),
            CreateReferralCode(settings: self),
            AddReferral(settings: self),
            AddClaim(settings: self),
            ChangeSearchCount(settings: self),
            ResetSearchCount(settings: self),
            ResetDefaultBrowserNudgeCard(settings: self),
            AnalyticsIdentifierSetting(settings: self),
            RefreshStatisticsSetting(settings: self),
        ]

        if EcosiaEnvironment.current == .staging {
            hiddenDebugSettings.append(AnalyticsStagingUrlSetting(settings: self))
        }

        return SettingSection(title: NSAttributedString(string: "Debug"), children: hiddenDebugSettings)
    }

    private func getEcosiaDebugUnleashSection() -> SettingSection {
        let unleashSettings: [Setting] = [
            UnleashBrazeIntegrationSetting(settings: self),
            UnleashNativeSRPVAnalyticsSetting(settings: self),
            UnleashAISearchMVPSetting(settings: self),
            UnleashIdentifierSetting(settings: self)
        ]

        return SettingSection(title: NSAttributedString(string: "Debug - Unleash"), children: unleashSettings)
    }

    private func getEcosiaDebugAccountsSection() -> SettingSection {
        let accountSettings: [Setting] = [
            ResetAccountImpactNudgeCard(settings: self),
            DebugAddSeedsLoggedOut(settings: self),
            DebugAddSeedsLoggedIn(settings: self),
            DebugAddCustomSeeds(settings: self),
            DebugForceLevelUp(settings: self),
            SimulateAuthErrorSetting(settings: self),
            SimulateImpactAPIErrorSetting(settings: self)
        ]

        return SettingSection(title: NSAttributedString(string: "Debug - Accounts"), children: accountSettings)
    }
}

// MARK: - Default Browser Nudge Card helpers

extension AppSettingsTableViewController {

    func isDefaultBrowserCell(_ section: Int) -> Bool {
        settings[section].children.first?.accessibilityIdentifier == AccessibilityIdentifiers.Settings.DefaultBrowser.defaultBrowser
    }

    func shouldShowDefaultBrowserNudgeCardInSection(_ section: Int) -> Bool {
        isDefaultBrowserCell(section) &&
        User.shared.shouldShowDefaultBrowserSettingNudgeCard
    }

    func hideDefaultBrowserNudgeCardInSection(_ section: Int) {
        guard section < settings.count else { return }
        self.settings.remove(at: section)
        self.tableView.deleteSections(IndexSet(integer: section), with: .automatic)
    }

    func showDefaultBrowserDetailView() {
        DefaultBrowserCoordinator.makeDefaultCoordinatorAndShowDetailViewFrom(navigationController,
                                                                              analyticsLabel: .settingsNudgeCard,
                                                                              topViewContentBackground: EcosiaColor.DarkGreen50.color,
                                                                              with: themeManager.getCurrentTheme(for: windowUUID))
    }
}
