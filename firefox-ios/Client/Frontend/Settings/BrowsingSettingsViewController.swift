// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Shared

/// Child settings pages browsing actions
protocol BrowsingSettingsDelegate: AnyObject {
    func pressedMailApp()
    func pressedAutoPlay()
}

class BrowsingSettingsViewController: SettingsTableViewController, FeatureFlaggable {
    weak var parentCoordinator: BrowsingSettingsDelegate?

    init(profile: Profile,
         windowUUID: WindowUUID) {
        super.init(style: .grouped, windowUUID: windowUUID)
        self.profile = profile
        self.title = .Settings.Browsing.Title
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func getDefaultBrowserSetting() -> [SettingSection] {
        let footerTitle = NSAttributedString(
            string: String.FirefoxHomepage.HomeTabBanner.EvergreenMessage.HomeTabBannerDescription)

        return [SettingSection(footerTitle: footerTitle,
                               children: [DefaultBrowserSetting(theme: themeManager.getCurrentTheme(for: windowUUID))])]
    }

    override func generateSettings() -> [SettingSection] {
        var settings = [SettingSection]()

        // Setting only available for iPad
        if let profile, UIDevice.current.userInterfaceIdiom == .pad {
            var generalSettings = [Setting]()
            let toolbarHide = BoolSetting(prefs: profile.prefs,
                                          theme: themeManager.getCurrentTheme(for: windowUUID),
                                          prefKey: PrefsKeys.UserFeatureFlagPrefs.TabsAndAddressBarAutoHide,
                                          defaultValue: true,
                                          titleText: .Settings.General.ScrollToHideTabAndAddressBar.Title)
            generalSettings.append(toolbarHide)
            settings.append(SettingSection(title: NSAttributedString(string: .SettingsGeneralSectionTitle),
                                           children: generalSettings))
        }

        if featureFlags.isFeatureEnabled(.inactiveTabs, checking: .buildOnly)
            && !featureFlags.isFeatureEnabled(.tabTrayUIExperiments, checking: .buildOnly) {
            let inactiveTabsSetting = BoolSetting(with: .inactiveTabs,
                                                  titleText: NSAttributedString(string: .Settings.Tabs.InactiveTabs))
            settings.append(
                SettingSection(
                    title: NSAttributedString(string: .Settings.Browsing.Tabs),
                    footerTitle: NSAttributedString(string: .Settings.Tabs.InactiveTabsDescription),
                    children: [inactiveTabsSetting]
                )
            )
        }

        var linksSettings: [Setting] = [OpenWithSetting(settings: self, settingsDelegate: parentCoordinator)]
        var mediaSection = [Setting]()
        if let profile {
            let theme = themeManager.getCurrentTheme(for: windowUUID)
            let offerToOpenCopiedLinksSettings = BoolSetting(
                prefs: profile.prefs,
                theme: theme,
                prefKey: PrefsKeys.ShowClipboardBar,
                defaultValue: false,
                titleText: .SettingsOfferClipboardBarTitle,
                statusText: String(format: .SettingsOfferClipboardBarStatus, AppName.shortName.rawValue)
            )

            let showLinksPreviewSettings = BoolSetting(
                prefs: profile.prefs,
                theme: theme,
                prefKey: PrefsKeys.ContextMenuShowLinkPreviews,
                defaultValue: true,
                titleText: .SettingsShowLinkPreviewsTitle,
                statusText: .SettingsShowLinkPreviewsStatus
            )

            linksSettings += [offerToOpenCopiedLinksSettings,
                              showLinksPreviewSettings]

            let blockOpeningExternalAppsSettings = BoolSetting(
                prefs: profile.prefs,
                theme: theme,
                prefKey: PrefsKeys.BlockOpeningExternalApps,
                defaultValue: false,
                titleText: .SettingsBlockOpeningExternalAppsTitle
            )

            let autoplaySetting = AutoplaySetting(theme: theme,
                                                  prefs: profile.prefs,
                                                  settingsDelegate: parentCoordinator)

            mediaSection += [
                autoplaySetting,
                BlockPopupSetting(prefs: profile.prefs),
                NoImageModeSetting(profile: profile),
                blockOpeningExternalAppsSettings
            ]
        }

        settings += [SettingSection(title: NSAttributedString(string: .Settings.Browsing.Links),
                                    children: linksSettings),
                     SettingSection(title: NSAttributedString(string: .Settings.Browsing.Media),
                                    children: mediaSection)]

        return settings
    }
}
