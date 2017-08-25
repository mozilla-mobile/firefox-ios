/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared

@available(iOS 11.0, *)
class ContentBlockerSettingViewController: SettingsTableViewController {
    let prefs: Prefs
    let EnabledStates = ContentBlockerHelper.EnabledState.allOptions
    let BlockingStrengths = ContentBlockerHelper.BlockingStrength.allOptions
    var currentEnabledState: ContentBlockerHelper.EnabledState
    var currentBlockingStrength: ContentBlockerHelper.BlockingStrength

    init(prefs: Prefs) {
        self.prefs = prefs
        currentEnabledState = ContentBlockerHelper.EnabledState(rawValue: prefs.stringForKey(ContentBlockerHelper.PrefKeyEnabledState) ?? "") ?? .onInPrivateBrowsing
        currentBlockingStrength = ContentBlockerHelper.BlockingStrength(rawValue: prefs.stringForKey(ContentBlockerHelper.PrefKeyStrength) ?? "") ?? .basic
        
        super.init(nibName: nil, bundle: nil)
        self.title = Strings.SettingsTrackingProtectionSectionName
        hasSectionSeparatorLine = false
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func generateSettings() -> [SettingSection] {
        let enabledSetting: [CheckmarkSetting] = EnabledStates.map { option in
            return CheckmarkSetting(title: NSAttributedString(string: option.settingTitle), subtitle: nil, isEnabled: {
                return option == self.currentEnabledState
            }, onChanged: {
                self.currentEnabledState = option
                self.prefs.setString(self.currentEnabledState.rawValue, forKey: ContentBlockerHelper.PrefKeyEnabledState)
                self.tableView.reloadData()
                ContentBlockerHelper.prefsChanged()
            })
        }

        let strengthSetting: [CheckmarkSetting] = BlockingStrengths.map { option in
            return CheckmarkSetting(title: NSAttributedString(string: option.settingTitle), subtitle: NSAttributedString(string: option.subtitle), isEnabled: {
                return option == self.currentBlockingStrength
            }, onChanged: {
                self.currentBlockingStrength = option
                self.prefs.setString(self.currentBlockingStrength.rawValue, forKey: ContentBlockerHelper.PrefKeyStrength)
                self.tableView.reloadData()
                ContentBlockerHelper.prefsChanged()
            })
        }

        let firstSection = SettingSection(title: NSAttributedString(string: Strings.TrackingProtectionOptionOnOffHeader), footerTitle: NSAttributedString(string: Strings.TrackingProtectionOptionOnOffFooter), children: enabledSetting)

        let blockListsTitle = Strings.TrackingProtectionOptionBlockListsTitle
        let secondSection = SettingSection(title: NSAttributedString(string: blockListsTitle), footerTitle: NSAttributedString(string: Strings.TrackingProtectionOptionFooter), children: strengthSetting)
        return [firstSection, secondSection]
    }
}
