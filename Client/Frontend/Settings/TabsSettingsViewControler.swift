// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation
import Shared

class TabsSettingsViewController: SettingsTableViewController, FeatureFlagsProtocol {

    init() {
        super.init(style: .grouped)

        self.title = .Settings.SectionTitles.TabsTitle
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func generateSettings() -> [SettingSection] {

        var sectionItems = [Setting]()

        let inactiveTabsSetting = BoolSetting(with: .inactiveTabs,
                                              titleText: NSAttributedString(string: .Settings.Tabs.InactiveTabs))

        let tabGroupsSetting = BoolSetting(with: .tabTrayGroups,
                                           titleText: NSAttributedString(string: .Settings.Tabs.TabGroups))

        if featureFlags.isFeatureActiveForBuild(.inactiveTabs),
           featureFlags.isFeatureActiveForNimbus(.inactiveTabs) {
            sectionItems.append(inactiveTabsSetting)
        }

        if featureFlags.isFeatureActiveForBuild(.tabTrayGroups) {
            sectionItems.append(tabGroupsSetting)
        }

        return [SettingSection(title: NSAttributedString(string: .Settings.Tabs.TabsSectionTitle),
                               children: sectionItems)]
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.keyboardDismissMode = .onDrag
    }
}
