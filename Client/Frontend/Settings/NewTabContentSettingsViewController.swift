/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared

class NewTabContentSettingsViewController: SettingsTableViewController {

    /* variables for checkmark settings */
    let prefs: Prefs
    var currentChoice: NewTabPage!
    var hasHomePage = false
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
        self.currentChoice = NewTabAccessors.getNewTabPage(self.prefs)
        self.hasHomePage = NewTabHomePageAccessors.getHomePage(self.prefs) != nil

        let onFinished = {
            self.prefs.setString(self.currentChoice.rawValue, forKey: NewTabAccessors.NewTabPrefKey)
            self.prefs.removeObjectForKey(HomePageConstants.NewTabCustomUrlPrefKey)
            self.tableView.reloadData()
        }

        let showTopSites = CheckmarkSetting(title: NSAttributedString(string: Strings.SettingsNewTabTopSites), subtitle: nil, accessibilityIdentifier: "NewTabAsFirefoxHome", isEnabled: {return self.currentChoice == NewTabPage.topSites}, onChanged: {
            self.currentChoice = NewTabPage.topSites
            onFinished()
        })
        let showBlankPage = CheckmarkSetting(title: NSAttributedString(string: Strings.SettingsNewTabBlankPage), subtitle: nil, accessibilityIdentifier: "NewTabAsBlankPage", isEnabled: {return self.currentChoice == NewTabPage.blankPage}, onChanged: {
            self.currentChoice = NewTabPage.blankPage
            onFinished()
        })
        let showBookmarks = CheckmarkSetting(title: NSAttributedString(string: Strings.SettingsNewTabBookmarks), subtitle: nil, accessibilityIdentifier: "NewTabAsBookmarks", isEnabled: {return self.currentChoice == NewTabPage.bookmarks}, onChanged: {
            self.currentChoice = NewTabPage.bookmarks
            onFinished()
        })
        let showHistory = CheckmarkSetting(title: NSAttributedString(string: Strings.SettingsNewTabHistory), subtitle: nil, accessibilityIdentifier: "NewTabAsHistory", isEnabled: {return self.currentChoice == NewTabPage.history}, onChanged: {
            self.currentChoice = NewTabPage.history
            onFinished()
        })

        let showWebPage = WebPageSetting(prefs: prefs, prefKey: HomePageConstants.NewTabCustomUrlPrefKey, defaultValue: nil, placeholder: Strings.CustomNewPageURL, accessibilityIdentifier: "NewTabAsCustomURL", settingDidChange: { (string) in
            self.currentChoice = NewTabPage.homePage
            self.prefs.setString(self.currentChoice.rawValue, forKey: NewTabAccessors.NewTabPrefKey)
            self.tableView.reloadData()
        })
        showWebPage.textField.textAlignment = .natural

        let section = SettingSection(title: NSAttributedString(string: Strings.NewTabSectionName), footerTitle: NSAttributedString(string: Strings.NewTabSectionNameFooter), children: [showTopSites, showBlankPage, showBookmarks, showHistory, showWebPage])

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
