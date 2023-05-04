// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Shared
import TabDataStore

protocol TabMigrationUtility {
    func shouldRunMigration(profile: Profile) -> Bool
    func startMigration(store: LegacyTabManagerStore)
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

    func startMigration(store: LegacyTabManagerStore) {
        Task {
            await runMigration(savedTabs: store.getSavedTabs)
        }
    }

    private func runMigration(savedTabs: [LegacySavedTab]) async {
        // Create TabData array from savedTabs
        var tabData = [TabData]()
        // TODO: Create tabData array from Save tabs
        // TODO: Investigate what UUID use for the migration
        // create WindowData
        let windowData = WindowData(id: UUID(),
                                    isPrimary: true,
                                    activeTabId: tabData.first?.id ?? UUID(),
                                    tabData: tabData)

        // Save migration WindowData
        await tabDataStore.saveWindowData(window: windowData)
    }
}
