// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Shared

/// Child settings pages browsing actions
protocol BrowsingSettingsDelegate: AnyObject {
    func pressedTabs()
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

    override func generateSettings() -> [SettingSection] {
        var childrenSection = [Setting]()

        if featureFlags.isFeatureEnabled(.inactiveTabs, checking: .buildOnly) {
            childrenSection += [TabsSetting(
                theme: themeManager.getCurrentTheme(for: windowUUID),
                settingsDelegate: parentCoordinator
            )]
        }

        childrenSection += [OpenWithSetting(settings: self, settingsDelegate: parentCoordinator)]

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

            let blockOpeningExternalAppsSettings = BoolSetting(
                prefs: profile.prefs,
                theme: themeManager.getCurrentTheme(for: windowUUID),
                prefKey: PrefsKeys.BlockOpeningExternalApps,
                defaultValue: false,
                titleText: .SettingsBlockOpeningExternalAppsTitle
            )

            childrenSection += [
                BlockPopupSetting(prefs: profile.prefs),
                NoImageModeSetting(profile: profile),
                offerToOpenCopiedLinksSettings,
                showLinksPreviewSettings,
                blockOpeningExternalAppsSettings
            ]
        }

        return [SettingSection(children: childrenSection)]
    }
}
