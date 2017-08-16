/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared

@available(iOS 11.0, *)
class ContentBlockerSettingViewController: SettingsTableViewController {
    let prefs: Prefs
    let enabledOptions = ContentBlockerHelper.EnabledOption.allOptions
    let strengthOptions = ContentBlockerHelper.StrengthOption.allOptions
    var currentEnabledOption: ContentBlockerHelper.EnabledOption = .onInPrivateBrowsing
    var currentStrengthOption: ContentBlockerHelper.StrengthOption = .basic

    init(prefs: Prefs) {
        self.prefs = prefs
        super.init(nibName: nil, bundle: nil)

        self.title = Strings.SettingsTrackingProtectionSectionName

        currentEnabledOption = ContentBlockerHelper.EnabledOption(rawValue: prefs.stringForKey(ContentBlockerHelper.PrefKeyEnabledState) ?? "") ?? .onInPrivateBrowsing
        currentStrengthOption = ContentBlockerHelper.StrengthOption(rawValue: prefs.stringForKey(ContentBlockerHelper.PrefKeyStrength) ?? "") ?? .basic
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func generateSettings() -> [SettingSection] {
        let enabledSetting: [CheckmarkSetting] = enabledOptions.map { option in
            return CheckmarkSetting(title: NSAttributedString(string: option.settingTitle), subtitle: nil, isEnabled: {
                return option == self.currentEnabledOption
            }, onChanged: {
                self.currentEnabledOption = option
                self.prefs.setString(self.currentEnabledOption.rawValue, forKey: ContentBlockerHelper.PrefKeyEnabledState)
                self.tableView.reloadData()
                ContentBlockerHelper.prefsChanged()
            })
        }

        let strengthSetting: [CheckmarkSetting] = strengthOptions.map { option in
            return CheckmarkSetting(title: NSAttributedString(string: option.settingTitle), subtitle: NSAttributedString(string: option.subtitle), isEnabled: {
                return option == self.currentStrengthOption
            }, onChanged: {
                self.currentStrengthOption = option
                self.prefs.setString(self.currentStrengthOption.rawValue, forKey: ContentBlockerHelper.PrefKeyStrength)
                self.tableView.reloadData()
                ContentBlockerHelper.prefsChanged()
            })
        }

        let firstSection = SettingSection(title: NSAttributedString(string: Strings.TrackingProtectionOptionOnOffHeader), footerTitle: NSAttributedString(string: Strings.TrackingProtectionOptionOnOffFooter), isFooterDoubleHeight: true, children: enabledSetting)
        let secondSection = SettingSection(title: NSAttributedString(string: Strings.TrackingProtectionOptionBlockListsTitle), footerTitle: NSAttributedString(string: Strings.TrackingProtectionOptionFooter), isFooterDoubleHeight: true, children: strengthSetting)
        return [firstSection, secondSection]
    }
}
