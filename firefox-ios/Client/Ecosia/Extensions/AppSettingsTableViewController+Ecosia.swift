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
            getEcosiaDefaultBrowserSection(),
            getSearchSection(),
            getCustomizationSection(),
            getEcosiaGeneralSection(),
            getEcosiaPrivacySection(),
            getEcosiaSupportSection(),
            getEcosiaAboutSection()
        ]

        if isDebugSectionEnabled {
            sections.append(getEcosiaDebugSupportSection())
        }

        return sections
    }
}

extension AppSettingsTableViewController {

    private func getEcosiaDefaultBrowserSection() -> SettingSection {
        .init(footerTitle: .init(string: .localized(.linksFromWebsites)),
              children: [DefaultBrowserSetting(theme: themeManager.getCurrentTheme(for: windowUUID))])
    }

    private func getSearchSection() -> SettingSection {

        var settings: [Setting] = [
            SearchAreaSetting(settings: self),
            SafeSearchSettings(settings: self),
            AutoCompleteSettings(prefs: profile.prefs, theme: themeManager.getCurrentTheme(for: windowUUID)),
            PersonalSearchSettings(prefs: profile.prefs, theme: themeManager.getCurrentTheme(for: windowUUID))
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
        .init(title: NSAttributedString(string: .AppSettingsSupport),
              children: [EcosiaSendFeedbackSetting()])
    }

    private func getEcosiaPrivacySection() -> SettingSection {
        let privacySettings = [
            PasswordManagerSetting(settings: self, settingsDelegate: parentCoordinator),
            ClearPrivateDataSetting(settings: self, settingsDelegate: parentCoordinator),
            EcosiaSendAnonymousUsageDataSetting(prefs: profile.prefs, theme: themeManager.getCurrentTheme(for: windowUUID)),
            BoolSetting(prefs: profile.prefs,
                        theme: themeManager.getCurrentTheme(for: windowUUID),
                        prefKey: "settings.closePrivateTabs",
                        defaultValue: false,
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

        var hiddenDebugSettings = [
            ExportBrowserDataSetting(settings: self),
            ForceCrashSetting(settings: self),
            PushBackInstallation(settings: self),
            OpenFiftyTabsDebugOption(settings: self, settingsDelegate: self),
            ToggleImpactIntro(settings: self),
            ShowTour(settings: self, windowUUID: windowUUID),
            CreateReferralCode(settings: self),
            AddReferral(settings: self),
            AddClaim(settings: self),
            ChangeSearchCount(settings: self),
            ResetSearchCount(settings: self),
            AnalyticsIdentifierSetting(settings: self),
            FasterInactiveTabs(settings: self, settingsDelegate: self),
            UnleashBrazeIntegrationSetting(settings: self),
            UnleashAPNConsent(settings: self),
            UnleashNativeSRPVAnalyticsSetting(settings: self),
            UnleashSeedCounterNTPSetting(settings: self),
        ]

        if SeedCounterNTPExperiment.isEnabled {
            hiddenDebugSettings.append(AddOneSeedSetting(settings: self,
                                                         progressManagerType: UserDefaultsSeedProgressManager.self))
            hiddenDebugSettings.append(AddFiveSeedsSetting(settings: self,
                                                           progressManagerType: UserDefaultsSeedProgressManager.self))
            hiddenDebugSettings.append(ResetSeedCounterSetting(settings: self,
                                                               progressManagerType: UserDefaultsSeedProgressManager.self))
        }

        return SettingSection(title: NSAttributedString(string: "Debug"), children: hiddenDebugSettings)
    }
}
