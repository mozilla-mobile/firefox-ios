// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Shared

/// Child settings pages browsing actions
protocol BrowsingSettingsDelegate: AnyObject {
    func pressedMailApp()
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

    // TODO: Laurie - Strings and prefKey
    override func generateSettings() -> [SettingSection] {
        var settings = [SettingSection]()

        if featureFlags.isFeatureEnabled(.inactiveTabs, checking: .buildOnly) {
            let inactiveTabsSetting = BoolSetting(with: .inactiveTabs,
                                                  titleText: NSAttributedString(string: .Settings.Tabs.InactiveTabs))

            // TODO: Laurie - Remove .Settings.Tabs.TabsSectionTitle),
            settings.append(
                SettingSection(
                    title: NSAttributedString(string: "TABS"),
                    footerTitle: NSAttributedString(string: .Settings.Tabs.InactiveTabsDescription),
                    children: [inactiveTabsSetting]
                )
            )
        }

        var linksSettings: [Setting] = [OpenWithSetting(settings: self, settingsDelegate: parentCoordinator)]
        if let profile {
            let offerToOpenCopiedLinksSettings = BoolSetting(
                prefs: profile.prefs,
                theme: themeManager.getCurrentTheme(for: windowUUID),
                prefKey: "showClipboardBar",
                defaultValue: false,
                titleText: .SettingsOfferClipboardBarTitle,
                statusText: String(format: .SettingsOfferClipboardBarStatus, AppName.shortName.rawValue)
            )

            let showLinksPreviewSettings = BoolSetting(
                prefs: profile.prefs,
                theme: themeManager.getCurrentTheme(for: windowUUID),
                prefKey: PrefsKeys.ContextMenuShowLinkPreviews,
                defaultValue: true,
                titleText: .SettingsShowLinkPreviewsTitle,
                statusText: .SettingsShowLinkPreviewsStatus
            )

            linksSettings += [offerToOpenCopiedLinksSettings,
                              showLinksPreviewSettings]
        }
        settings += [SettingSection(title: NSAttributedString(string: "LINKS"), children: linksSettings)]

        if let profile {
            var mediaSection = [Setting]()
            let blockOpeningExternalAppsSettings = BoolSetting(
                prefs: profile.prefs,
                theme: themeManager.getCurrentTheme(for: windowUUID),
                prefKey: PrefsKeys.BlockOpeningExternalApps,
                defaultValue: false,
                titleText: .SettingsBlockOpeningExternalAppsTitle
            )

            mediaSection += [
                BlockPopupSetting(prefs: profile.prefs),
                NoImageModeSetting(profile: profile),
                blockOpeningExternalAppsSettings
            ]

            settings += [SettingSection(title: NSAttributedString(string: "MEDIA"), children: mediaSection)]
        }

        return settings
    }
}
