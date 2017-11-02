/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import Sync

class SyncContentSettingsViewController: SettingsTableViewController {
    fileprivate var enginesToSyncOnExit: Set<String> = Set()

    init() {
        super.init(style: .grouped)

        self.title = Strings.SettingsSyncTitle
        hasSectionSeparatorLine = false
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillDisappear(_ animated: Bool) {
        if !enginesToSyncOnExit.isEmpty {
            _ = self.profile.syncManager.syncNamedCollections(why: SyncReason.engineEnabled, names: Array(enginesToSyncOnExit))
            enginesToSyncOnExit.removeAll()
        }
        super.viewWillDisappear(animated)
    }

    func engineSettingChanged(_ engineName: String) -> (Bool) -> Void {
        let prefName = "sync.engine.\(engineName).enabledStateChanged"
        return { enabled in
            if let _ = self.profile.prefs.boolForKey(prefName) { // Switch it back to not-changed
                self.profile.prefs.removeObjectForKey(prefName)
                self.enginesToSyncOnExit.remove(engineName)
            } else {
                self.profile.prefs.setBool(true, forKey: prefName)
                self.enginesToSyncOnExit.insert(engineName)
            }
        }
    }

    override func generateSettings() -> [SettingSection] {
        let bookmarks = BoolSetting(prefs: profile.prefs, prefKey: "sync.engine.bookmarks.enabled", defaultValue: true, attributedTitleText: NSAttributedString(string: Strings.FirefoxSyncBookmarksEngine), attributedStatusText: nil, settingDidChange: engineSettingChanged("bookmarks"))
        let history = BoolSetting(prefs: profile.prefs, prefKey: "sync.engine.history.enabled", defaultValue: true, attributedTitleText: NSAttributedString(string: Strings.FirefoxSyncHistoryEngine), attributedStatusText: nil, settingDidChange: engineSettingChanged("history"))
        let tabs = BoolSetting(prefs: profile.prefs, prefKey: "sync.engine.tabs.enabled", defaultValue: true, attributedTitleText: NSAttributedString(string: Strings.FirefoxSyncTabsEngine), attributedStatusText: nil, settingDidChange: engineSettingChanged("tabs"))
        let passwords = BoolSetting(prefs: profile.prefs, prefKey: "sync.engine.passwords.enabled", defaultValue: true, attributedTitleText: NSAttributedString(string: Strings.FirefoxSyncLoginsEngine), attributedStatusText: nil, settingDidChange: engineSettingChanged("passwords"))

        let syncOptions = SettingSection(title: NSAttributedString(string: Strings.SettingsSyncSectionName), footerTitle: nil, children: [bookmarks, history, tabs, passwords])

        return [syncOptions]
    }
}
