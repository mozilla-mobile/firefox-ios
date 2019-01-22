/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared

class TabSettingsViewController: SettingsTableViewController {
    
    /* variables for checkmark settings */
    let prefs: Prefs
    init(prefs: Prefs) {
        self.prefs = prefs
        super.init(style: .grouped)
        
        self.title = Strings.SettingsTabsTitle
        hasSectionSeparatorLine = false
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func generateSettings() -> [SettingSection] {
        let switchToNewTabSetting = BoolSetting(prefs: profile.prefs, prefKey: PrefsKeys.KeySwitchToNewTabImmediately, defaultValue: true, attributedTitleText: NSAttributedString(string: Strings.SettingsTabsImmediateSwitch))
        let section = SettingSection(title: NSAttributedString(string: Strings.SettingsTabsImmediateSwitchTitle), footerTitle: nil, children: [switchToNewTabSetting])
        
        return [section]
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.post(name: .HomePanelPrefsChanged, object: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.keyboardDismissMode = .onDrag
    }
}
