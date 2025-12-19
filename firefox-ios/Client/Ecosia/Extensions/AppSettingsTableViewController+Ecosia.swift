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

        let settings: [Setting] = [
            EcosiaDefaultBrowserSettings(),
            SearchAreaSetting(settings: self),
            SafeSearchSettings(settings: self),
            AutoCompleteSettings(prefs: profile.prefs, theme: themeManager.getCurrentTheme(for: windowUUID)),
            PersonalSearchSettings(prefs: profile.prefs, theme: themeManager.getCurrentTheme(for: windowUUID)),
            AIOverviewsSearchSettings(prefs: profile.prefs, theme: themeManager.getCurrentTheme(for: windowUUID))
        ]

        return .init(title: .init(string: .localized(.search)),
                     children: settings)
    }

    private func getCustomizationSection() -> SettingSection {

        var customizationSettings: [Setting] = [
            HomepageSettings(settings: self, settingsDelegate: settingsDelegate)
        ]

        let inactiveTabsAreBuildActive = featureFlags.isFeatureEnabled(.inactiveTabs, checking: .buildOnly)

        if inactiveTabsAreBuildActive {
            customizationSettings.append(TabsSetting(theme: themeManager.getCurrentTheme(for: windowUUID), settingsDelegate: parentCoordinator))
        }

        if isSearchBarLocationFeatureEnabled {
            customizationSettings.append(SearchBarSetting(settings: self, settingsDelegate: parentCoordinator))
        }

        return .init(title: .init(string: .localized(.customization)),
                     children: customizationSettings)
    }

    private func getEcosiaGeneralSection() -> SettingSection {

        let generalSettings: [Setting] = [
            OpenWithSetting(settings: self, settingsDelegate: parentCoordinator),
            ThemeSetting(settings: self, settingsDelegate: parentCoordinator),
            SiriPageSetting(settings: self, settingsDelegate: parentCoordinator),
            BlockPopupSetting(settings: self),
            NoImageModeSetting(settings: self),
            BoolSetting(
                prefs: profile.prefs,
                theme: themeManager.getCurrentTheme(for: windowUUID),
                prefKey: "showClipboardBar",
                defaultValue: false,
                titleText: .SettingsOfferClipboardBarTitle,
                statusText: String(format: .SettingsOfferClipboardBarStatus, AppName.shortName.rawValue)
            ),
            BoolSetting(
                prefs: profile.prefs,
                theme: themeManager.getCurrentTheme(for: windowUUID),
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
        let privacySettings = [
            PasswordManagerSetting(settings: self, settingsDelegate: parentCoordinator),
            ClearPrivateDataSetting(settings: self, settingsDelegate: parentCoordinator),
            EcosiaSendAnonymousUsageDataSetting(prefs: profile.prefs, theme: themeManager.getCurrentTheme(for: windowUUID)),
            BoolSetting(prefs: profile.prefs,
                        theme: themeManager.getCurrentTheme(for: windowUUID),
                        prefKey: PrefsKeys.Settings.closePrivateTabs,
                        // Ecosia: Default value is different from Firefox
                        defaultValue: PrefsKeysDefaultValues.Settings.closePrivateTabs,
                        titleText: .AppSettingsClosePrivateTabsTitle,
                        statusText: .AppSettingsClosePrivateTabsDescription),
            ContentBlockerSetting(settings: self, settingsDelegate: parentCoordinator),
            EcosiaPrivacyPolicySetting(settings: self),
            EcosiaTermsSetting(settings: self)
        ]

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
            FasterInactiveTabs(settings: self, settingsDelegate: self),
            AnalyticsIdentifierSetting(settings: self),
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
