// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import Common

class NewTabContentSettingsViewController: SettingsTableViewController {
    /* variables for checkmark settings */
    let prefs: Prefs
    var currentChoice: NewTabPage?
    var hasHomePage = false
    init(prefs: Prefs, windowUUID: WindowUUID) {
        self.prefs = prefs
        super.init(style: .grouped, windowUUID: windowUUID)

        self.title = .SettingsNewTabTitle
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func generateSettings() -> [SettingSection] {
        self.currentChoice = NewTabAccessors.getNewTabPage(self.prefs)
        self.hasHomePage = NewTabHomePageAccessors.getHomePage(self.prefs) != nil

        let onFinished = {
            guard let currentChoice = self.currentChoice else { return }
            self.prefs.setString(currentChoice.rawValue, forKey: NewTabAccessors.NewTabPrefKey)
            self.tableView.reloadData()
        }

        let showTopSites = CheckmarkSetting(
            title: NSAttributedString(string: .SettingsNewTabTopSites),
            subtitle: nil,
            accessibilityIdentifier: "NewTabAsFirefoxHome",
            isChecked: { return self.currentChoice == NewTabPage.topSites },
            onChecked: {
                self.currentChoice = NewTabPage.topSites
                onFinished()
            }
        )

        let showBlankPage = CheckmarkSetting(
            title: NSAttributedString(string: .SettingsNewTabBlankPage),
            subtitle: nil,
            accessibilityIdentifier: "NewTabAsBlankPage",
            isChecked: { return self.currentChoice == NewTabPage.blankPage },
            onChecked: {
                self.currentChoice = NewTabPage.blankPage
                onFinished()
            }
        )

        let showWebPage = WebPageSetting(
            prefs: prefs,
            prefKey: PrefsKeys.NewTabCustomUrlPrefKey,
            defaultValue: nil,
            placeholder: .CustomNewPageURL,
            accessibilityIdentifier: "NewTabAsCustomURL",
            isChecked: { return !showTopSites.isChecked() && !showBlankPage.isChecked() },
            settingDidChange: { (string) in
                self.currentChoice = NewTabPage.homePage
                onFinished()
            }
        )

        showWebPage.alignTextFieldToNatural()

        let section = SettingSection(
            title: NSAttributedString(string: .NewTabSectionName),
            footerTitle: NSAttributedString(string: .NewTabSectionNameFooter),
            children: [showTopSites, showBlankPage, showWebPage])

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
