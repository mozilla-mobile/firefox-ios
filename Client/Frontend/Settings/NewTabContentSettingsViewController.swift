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
        super.init(title: NSAttributedString(string: NewTabAccessors.getNewTabPage(profile.prefs).settingTitle, attributes: [NSAttributedStringKey.foregroundColor: SettingsUX.TableViewRowTextColor]))
    }

    override func onClick(_ navigationController: UINavigationController?) {
        let viewController = NewTabChoiceViewController(prefs: profile.prefs)
        navigationController?.pushViewController(viewController, animated: true)
    }
}

class NewTabContentSettingsViewController: SettingsTableViewController {

    /* variables for checkmark settings */
    let prefs: Prefs
    var currentChoice: NewTabPage!
    var hasHomePage: Bool!

    init(prefs: Prefs) {
        self.prefs = prefs
        super.init(style: .grouped)

        self.title = Strings.SettingsNewTabTitle
        hasSectionSeparatorLine = false
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func generateSettings() -> [SettingSection] {
        //let tabSetting = CurrentTabSetting(profile: profile)
        self.currentChoice = NewTabAccessors.getNewTabPage(self.prefs)
        self.hasHomePage = HomePageAccessors.getHomePage(self.prefs) != nil

        let showTopSites = CheckmarkSetting(title: NSAttributedString(string: Strings.SettingsNewTabTopSites), subtitle: nil, accessibilityIdentifier: nil, isEnabled: {return self.currentChoice == NewTabPage.topSites}, onChanged: {
            self.currentChoice = NewTabPage.topSites
            self.prefs.setString(self.currentChoice.rawValue, forKey: NewTabAccessors.PrefKey)
            self.tableView.reloadData()
        })
        let showBlankPage = CheckmarkSetting(title: NSAttributedString(string: Strings.SettingsNewTabBlankPage), subtitle: nil, accessibilityIdentifier: nil, isEnabled: {return self.currentChoice == NewTabPage.blankPage}, onChanged: {
            self.currentChoice = NewTabPage.blankPage
            self.prefs.setString(self.currentChoice.rawValue, forKey: NewTabAccessors.PrefKey)
            self.tableView.reloadData()
        })
        let showBookmarks = CheckmarkSetting(title: NSAttributedString(string: Strings.SettingsNewTabBookmarks), subtitle: nil, accessibilityIdentifier: nil, isEnabled: {return self.currentChoice == NewTabPage.bookmarks}, onChanged: {
            self.currentChoice = NewTabPage.bookmarks
            self.prefs.setString(self.currentChoice.rawValue, forKey: NewTabAccessors.PrefKey)
            self.tableView.reloadData()
        })
        let showHistory = CheckmarkSetting(title: NSAttributedString(string: Strings.SettingsNewTabHistory), subtitle: nil, accessibilityIdentifier: nil, isEnabled: {return self.currentChoice == NewTabPage.history}, onChanged: {
            self.currentChoice = NewTabPage.history
            self.prefs.setString(self.currentChoice.rawValue, forKey: NewTabAccessors.PrefKey)
            self.tableView.reloadData()
        })
        let showHomepage = CheckmarkSetting(title: NSAttributedString(string: Strings.SettingsNewTabHomePage), subtitle: nil, accessibilityIdentifier: nil, isEnabled: {return (self.currentChoice == NewTabPage.homePage) && self.hasHomePage}, onChanged: {
            self.hasHomePage = HomePageAccessors.getHomePage(self.prefs) != nil
            if self.hasHomePage {
                self.currentChoice = NewTabPage.homePage
                self.prefs.setString(self.currentChoice.rawValue, forKey: NewTabAccessors.PrefKey)
            }
            self.tableView.reloadData()
        })
        let firstSection = SettingSection(title: NSAttributedString(string: Strings.NewTabSectionName), footerTitle: NSAttributedString(string: Strings.NewTabSectionNameFooter), children: [showTopSites, showBlankPage, showBookmarks, showHistory, showHomepage])
        
        let isPocketEnabledDefault = Pocket.IslocaleSupported(Locale.current.identifier)
        let pocketSetting = BoolSetting(prefs: profile.prefs, prefKey: PrefsKeys.ASPocketStoriesVisible, defaultValue: isPocketEnabledDefault, attributedTitleText: NSAttributedString(string: Strings.SettingsNewTabPocket))
        let bookmarks = BoolSetting(prefs: profile.prefs, prefKey: PrefsKeys.ASBookmarkHighlightsVisible, defaultValue: true, attributedTitleText: NSAttributedString(string: Strings.SettingsNewTabHighlightsBookmarks))
        let history = BoolSetting(prefs: profile.prefs, prefKey: PrefsKeys.ASRecentHighlightsVisible, defaultValue: true, attributedTitleText: NSAttributedString(string: Strings.SettingsNewTabHiglightsHistory))
        let secondSection = SettingSection(title: NSAttributedString(string: Strings.SettingsNewTabASTitle), footerTitle: nil, children: [pocketSetting, bookmarks, history])

        return [firstSection, secondSection]

    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.post(name: .HomePanelPrefsChanged, object: nil)
    }
}

