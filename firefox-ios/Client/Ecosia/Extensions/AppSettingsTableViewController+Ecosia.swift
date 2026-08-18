// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit
import Shared
import Ecosia

// MARK: - Ecosia Settings Sections
// These sections are called from generateSettings() in AppSettingsTableViewController.swift
// to integrate Ecosia-specific settings into Firefox's settings flow.

extension AppSettingsTableViewController {

    func getSearchSection() -> [SettingSection] {
        guard let profile else {
            return [SettingSection(title: .init(string: .localized(.search)), children: [
                EcosiaDefaultBrowserSettings(),
                SearchAreaSetting(settings: self),
                SafeSearchSettings(settings: self)
            ])]
        }
        let theme = themeManager.getCurrentTheme(for: windowUUID)
        let settings: [Setting] = [
            EcosiaDefaultBrowserSettings(),
            SearchAreaSetting(settings: self),
            SafeSearchSettings(settings: self),
            AutoCompleteSettings(prefs: profile.prefs, theme: theme),
            AIOverviewsSearchSettings(prefs: profile.prefs, theme: theme)
        ]

        return [SettingSection(title: .init(string: .localized(.search)),
                               children: settings)]
    }

    func getCustomizationSection() -> [SettingSection] {
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

        return [SettingSection(title: .init(string: .localized(.customization)),
                               children: customizationSettings)]
    }
}

// MARK: - Ecosia Debug Sections

extension AppSettingsTableViewController {

    func getEcosiaDebugSupportSection() -> SettingSection {
        /* Ecosia: FasterInactiveTabs removed in Firefox upgrade; re-add if type is restored */
        var hiddenDebugSettings: [Setting] = [
            ExportBrowserDataSetting(settings: self),
            ForceCrashSetting(settings: self),
            EcosiaLoggerForceErrorSetting(settings: self),
            PushBackInstallation(settings: self),
            OpenFiftyTabsDebugOption(settings: self, settingsDelegate: self),
            ToggleDefaultBrowserPromo(settings: self),
            ShowWelcomeScreen(settings: self),
            ToggleImpactIntro(settings: self),
            CreateReferralCode(settings: self),
            AddReferral(settings: self),
            AddClaim(settings: self),
            ChangeSearchCount(settings: self),
            ResetSearchCount(settings: self),
            ResetDefaultBrowserNudgeCard(settings: self),
            /* Ecosia: FasterInactiveTabs removed in Firefox upgrade; restore when type is available again
            FasterInactiveTabs(settings: self, settingsDelegate: self),
            */
            AnalyticsIdentifierSetting(settings: self),
            RefreshStatisticsSetting(settings: self),
        ]

        if EcosiaEnvironment.current == .staging {
            hiddenDebugSettings.append(AnalyticsStagingUrlSetting(settings: self))
        }

        return SettingSection(title: NSAttributedString(string: "Debug"), children: hiddenDebugSettings)
    }

    func getEcosiaDebugUnleashSection() -> SettingSection {
        let unleashSettings: [Setting] = [
            UnleashBrazeIntegrationSetting(settings: self),
            UnleashNativeSRPVAnalyticsSetting(settings: self),
            UnleashAIChatMVPSetting(settings: self),
            UnleashIdentifierSetting(settings: self)
        ]

        return SettingSection(title: NSAttributedString(string: "Debug - Unleash"), children: unleashSettings)
    }

    func getEcosiaDebugAccountsSection() -> SettingSection {
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

    func getEcosiaDebugFileUploadSection() -> SettingSection {
        let fileUploadSettings: [Setting] = [
            SimulateFileUploadAPIErrorSetting(settings: self),
            SimulateUploadValidationErrorSetting(simulatedError: .tooManyFiles, settings: self),
            SimulateUploadValidationErrorSetting(simulatedError: .fileTooLarge, settings: self),
            SimulateUploadValidationErrorSetting(simulatedError: .unsupportedFileType, settings: self)
        ]

        return SettingSection(title: NSAttributedString(string: "Debug - File Upload"), children: fileUploadSettings)
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
