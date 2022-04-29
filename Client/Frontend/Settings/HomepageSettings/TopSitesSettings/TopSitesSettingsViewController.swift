// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared

class TopSitesSettingsViewController: SettingsTableViewController {

    // MARK: - Initializers
    init() {
        super.init(style: .grouped)

        self.title = .Settings.Homepage.Shortcuts.ShortcutsPageTitle
        self.navigationController?.navigationBar.accessibilityIdentifier = AccessibilityIdentifiers.Settings.Homepage.CustomizeFirefox.Shortcuts.settingsPage
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Methods
    override func generateSettings() -> [SettingSection] {
        let topSitesSetting = BoolSetting(with: .topSites,
                                          titleText: NSAttributedString(string: .Settings.Homepage.Shortcuts.ShortcutsToggle))

        // TODO: Only show setting if Nimbus enabled https://mozilla-hub.atlassian.net/browse/FXIOS-3468
        let sponsoredShortcutSetting = BoolSetting(with: .sponsoredTiles,
                                                   titleText: NSAttributedString(string: .Settings.Homepage.Shortcuts.SponsoredShortcutsToggle))

        let toggleSection = SettingSection(title: nil,
                                           children: [topSitesSetting, sponsoredShortcutSetting])

        let rowSetting = RowSettings(settings: self)
        let rowSection = SettingSection(title: nil, children: [rowSetting])

        return [toggleSection, rowSection]
    }
}

// MARK: - TopSitesSettings
extension TopSitesSettingsViewController {
    class RowSettings: Setting {
        let profile: Profile

        override var accessoryType: UITableViewCell.AccessoryType { return .disclosureIndicator }
        override var status: NSAttributedString {
            let numberOfRows = profile.prefs.intForKey(PrefsKeys.NumberOfTopSiteRows) ?? TopSitesRowCountSettingsController.defaultNumberOfRows
            return NSAttributedString(string: String(format: "%d", numberOfRows))
        }

        override var accessibilityIdentifier: String? { return AccessibilityIdentifiers.Settings.Homepage.CustomizeFirefox.Shortcuts.topSitesRows }
        override var style: UITableViewCell.CellStyle { return .value1 }

        init(settings: SettingsTableViewController) {
            self.profile = settings.profile
            super.init(title: NSAttributedString(string: .Settings.Homepage.Shortcuts.Rows,
                                                 attributes: [NSAttributedString.Key.foregroundColor: UIColor.theme.tableView.rowText]))
        }

        override func onClick(_ navigationController: UINavigationController?) {
            let viewController = TopSitesRowCountSettingsController(prefs: profile.prefs)
            viewController.profile = profile
            navigationController?.pushViewController(viewController, animated: true)
        }
    }
}
