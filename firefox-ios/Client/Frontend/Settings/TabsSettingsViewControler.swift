// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import Common

class TabsSettingsViewController: SettingsTableViewController, FeatureFlaggable {
    init(windowUUID: WindowUUID) {
        super.init(style: .grouped, windowUUID: windowUUID)

        self.title = .Settings.SectionTitles.TabsTitle
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func generateSettings() -> [SettingSection] {
        var sectionItems = [SettingSection]()

        let inactiveTabsSetting = BoolSetting(with: .inactiveTabs,
                                              titleText: NSAttributedString(string: .Settings.Tabs.InactiveTabs))

        if featureFlags.isFeatureEnabled(.inactiveTabs, checking: .buildOnly) {
            sectionItems.append(
                SettingSection(
                    title: NSAttributedString(string: .Settings.Tabs.TabsSectionTitle),
                    footerTitle: NSAttributedString(string: .Settings.Tabs.InactiveTabsDescription),
                    children: [inactiveTabsSetting]
                )
            )
        }

        return sectionItems
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.keyboardDismissMode = .onDrag
    }
}
