// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common
import Shared

class TopSitesSettingsViewController: SettingsTableViewController, FeatureFlaggable {
    // MARK: - Initializers
    init(windowUUID: WindowUUID) {
        super.init(style: .grouped, windowUUID: windowUUID)

        self.title = .Settings.Homepage.Shortcuts.ShortcutsPageTitle
        self.navigationController?.navigationBar.accessibilityIdentifier = AccessibilityIdentifiers
            .Settings.Homepage.CustomizeFirefox.Shortcuts.settingsPage
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.post(name: .HomePanelPrefsChanged, object: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Methods
    override func generateSettings() -> [SettingSection] {
        var sections = [Setting]()
        let topSitesSetting = BoolSetting(
            prefs: profile.prefs,
            theme: themeManager.getCurrentTheme(for: windowUUID),
            prefKey: PrefsKeys.UserFeatureFlagPrefs.TopSiteSection,
            defaultValue: true,
            titleText: .Settings.Homepage.Shortcuts.ShortcutsToggle
        )
        sections.append(topSitesSetting)

        let sponsoredShortcutSetting = BoolSetting(
            prefs: profile.prefs,
            theme: themeManager.getCurrentTheme(for: windowUUID),
            prefKey: PrefsKeys.UserFeatureFlagPrefs.SponsoredShortcuts,
            defaultValue: true,
            titleText: .Settings.Homepage.Shortcuts.SponsoredShortcutsToggle
        )
        sections.append(sponsoredShortcutSetting)

        let toggleSection = SettingSection(title: nil,
                                           children: sections)

        let rowSetting = RowSettings(settings: self)
        let rowSection = SettingSection(title: nil, children: [rowSetting])

        return [toggleSection, rowSection]
    }
}

// MARK: - TopSitesSettings
extension TopSitesSettingsViewController {
    class RowSettings: Setting {
        let profile: Profile
        let windowUUID: WindowUUID

        override var accessoryType: UITableViewCell.AccessoryType { return .disclosureIndicator }
        override var status: NSAttributedString {
            let defaultValue = TopSitesRowCountSettingsController.defaultNumberOfRows
            let numberOfRows = profile.prefs.intForKey(PrefsKeys.NumberOfTopSiteRows) ?? defaultValue

            return NSAttributedString(string: String(format: "%d", numberOfRows))
        }

        override var accessibilityIdentifier: String? {
            return AccessibilityIdentifiers.Settings.Homepage.CustomizeFirefox.Shortcuts.topSitesRows
        }
        override var style: UITableViewCell.CellStyle { return .value1 }

        init(settings: SettingsTableViewController) {
            self.profile = settings.profile
            self.windowUUID = settings.windowUUID
            let theme = settings.themeManager.getCurrentTheme(for: windowUUID)
            super.init(
                title: NSAttributedString(
                    string: .Settings.Homepage.Shortcuts.Rows,
                    attributes: [
                        NSAttributedString.Key.foregroundColor: theme.colors.textPrimary
                    ]
                )
            )
        }

        override func onClick(_ navigationController: UINavigationController?) {
            let viewController = TopSitesRowCountSettingsController(prefs: profile.prefs, windowUUID: windowUUID)
            viewController.profile = profile
            navigationController?.pushViewController(viewController, animated: true)
        }
    }
}
