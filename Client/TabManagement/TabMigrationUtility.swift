// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Shared
import TabDataStore

protocol TabMigrationUtility {
    func shouldRunMigration(profile: Profile) -> Bool
    func startMigration(savedTabs: [LegacySavedTab]) async
}

class DefaultTabMigrationUtility: TabMigrationUtility {
    private let migrationKey = PrefsKeys.TabMigrationKey
    private var tabDataStore: TabDataStore
    // TODO: Use file manager to write tabData create a windowObject

    init(tabDataStore: TabDataStore = DefaultTabDataStore()) {
        self.tabDataStore = tabDataStore
    }

    func shouldRunMigration(profile: Profile) -> Bool {
        guard let migrationPerformed = profile.prefs.boolForKey(migrationKey) else { return true }

        return migrationPerformed
    }

    func startMigration(savedTabs: [LegacySavedTab]) async {
        // Create TabData array from savedTabs
        var tabsToMigrate = [TabData]()

        var selectTabUUID: UUID?
        for savedTab in savedTabs {
            let savedTabUUID = savedTab.screenshotUUID ?? UUID()

            let tabGroupData = TabGroupData(
                searchTerm: savedTab.tabGroupData?.tabAssociatedSearchTerm,
                searchUrl: savedTab.tabGroupData?.tabAssociatedSearchUrl,
                nextUrl: savedTab.tabGroupData?.tabAssociatedNextUrl,
                tabHistoryCurrentState: TabGroupTimerState(rawValue: savedTab.tabGroupData?.tabHistoryCurrentState ?? "")
            )

            let tabData = TabData(id: savedTabUUID,
                                  title: savedTab.title,
                                  siteUrl: savedTab.url?.absoluteString ?? "",
                                  faviconURL: savedTab.faviconURL,
                                  isPrivate: savedTab.isPrivate,
                                  lastUsedTime: Date.fromTimestamp(savedTab.sessionData?.lastUsedTime ?? Date().toTimestamp()),
                                  createdAtTime: Date.fromTimestamp(savedTab.createdAt ?? Date().toTimestamp()),
                                  tabGroupData: tabGroupData)

            if savedTab.isSelected {
                selectTabUUID = savedTab.screenshotUUID
            }
            tabsToMigrate.append(tabData)
        }

        let windowData = WindowData(id: UUID(uuidString: "44BA0B7D-097A-484D-8358-91A6E374451D")!,
                                    isPrimary: true,
                                    activeTabId: selectTabUUID ?? UUID(),
                                    tabData: tabsToMigrate)

        // Save migration WindowData
        await tabDataStore.saveWindowData(window: windowData)
    }
}
