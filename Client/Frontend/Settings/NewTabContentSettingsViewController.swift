/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared

class CurrentTabSetting: Setting {
    let profile: Profile

    override var accessoryType: UITableViewCellAccessoryType { return .disclosureIndicator }

    override var style: UITableViewCellStyle { return .value1 }

    override var accessibilityIdentifier: String? { return "NewTabOption" }

    init(profile: Profile) {
        self.profile = profile
        super.init(title: NSAttributedString(string: NewTabAccessors.getNewTabPage(profile.prefs).settingTitle, attributes: [NSForegroundColorAttributeName: UIConstants.TableViewRowTextColor]))
    }

    override func onClick(_ navigationController: UINavigationController?) {
        let viewController = NewTabChoiceViewController(prefs: profile.prefs)
        navigationController?.pushViewController(viewController, animated: true)
    }
}

class NewTabContentSettingsViewController: SettingsTableViewController {

    init() {
        super.init(style: .grouped)

        self.title = Strings.SettingsNewTabTitle
        hasSectionSeparatorLine = false
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func generateSettings() -> [SettingSection] {
        let tabSetting = CurrentTabSetting(profile: profile)
        let firstSection = SettingSection(title: NSAttributedString(string: Strings.SettingsNewTabSectionName), footerTitle: nil, children: [tabSetting])
        
        let isPocketEnabledDefault = Pocket.IslocaleSupported(Locale.current.identifier)
        let pocketSetting = BoolSetting(prefs: profile.prefs, prefKey: PrefsKeys.ASPocketStoriesVisible, defaultValue: isPocketEnabledDefault, attributedTitleText: NSAttributedString(string: Strings.SettingsNewTabPocket))
        let bookmarks = BoolSetting(prefs: profile.prefs, prefKey: PrefsKeys.ASBookmarkHighlightsVisible, defaultValue: true, attributedTitleText: NSAttributedString(string: Strings.SettingsNewTabHighlightsBookmarks))
        let history = BoolSetting(prefs: profile.prefs, prefKey: PrefsKeys.ASRecentHighlightsVisible, defaultValue: true, attributedTitleText: NSAttributedString(string: Strings.SettingsNewTabHiglightsHistory))
        let options = AppConstants.MOZ_POCKET_STORIES ? [pocketSetting, bookmarks, history] : [bookmarks, history]
        let secondSection = SettingSection(title: NSAttributedString(string: Strings.SettingsNewTabASTitle), footerTitle: nil, children: options)

        return [firstSection, secondSection]
    }
}

