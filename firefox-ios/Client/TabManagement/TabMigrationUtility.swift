// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Shared
import TabDataStore

protocol TabMigrationUtility {
    var shouldRunMigration: Bool { get }
    var legacyTabs: [LegacySavedTab] { get set }
    func runMigration(for windowUUID: WindowUUID) async -> WindowData
}

class DefaultTabMigrationUtility: TabMigrationUtility {
    private let tabsKey = "tabs"
    private let migrationKey = PrefsKeys.TabMigrationKey
    private let prefs: Prefs
    private let tabDataStore: TabDataStore
    private let logger: Logger
    private var legacyTabDataRetriever: LegacyTabDataRetriever
    var legacyTabs = [LegacySavedTab]()

    init(profile: Profile = AppContainer.shared.resolve(),
         tabDataStore: TabDataStore,
         logger: Logger = DefaultLogger.shared,
         legacyTabDataRetriever: LegacyTabDataRetriever = LegacyTabDataRetrieverImplementation()) {
        self.prefs = profile.prefs
        self.tabDataStore = tabDataStore
        self.logger = logger
        self.legacyTabDataRetriever = legacyTabDataRetriever
        self.legacyTabs = getLegacyTabs()
    }

    var shouldRunMigration: Bool {
        guard let shouldRunMigration = prefs.boolForKey(migrationKey) else {
            logger.log("Should run migration will be TRUE, key didnt exist",
                       level: .debug,
                       category: .tabs)
            return true
        }

        logger.log("Key exists - running migration? \(shouldRunMigration)",
                   level: .debug,
                   category: .tabs)
        return shouldRunMigration
    }

    func getLegacyTabs() -> [LegacySavedTab] {
        guard let tabData = legacyTabDataRetriever.getTabData() else {
            return []
        }

        do {
            let unarchiver = try NSKeyedUnarchiver(forReadingFrom: tabData)
            guard let tabs = unarchiver.decodeDecodable([LegacySavedTab].self, forKey: tabsKey) else {
                return []
            }
            return tabs
        } catch {
            return []
        }
    }

    func runMigration(for windowUUID: WindowUUID) async -> WindowData {
        logger.log("Begin tab migration with legacy tab count \(legacyTabs.count)",
                   level: .debug,
                   category: .tabs)
        // Create TabData array from legacyTabs
        var tabsToMigrate = [TabData]()

        var selectTabUUID: UUID?
        for savedTab in legacyTabs {
            let savedTabUUID = savedTab.screenshotUUID ?? UUID()

            let tabGroupData = TabGroupData(
                searchTerm: savedTab.tabGroupData?.tabAssociatedSearchTerm,
                searchUrl: savedTab.tabGroupData?.tabAssociatedSearchUrl,
                nextUrl: savedTab.tabGroupData?.tabAssociatedNextUrl,
                tabHistoryCurrentState: TabGroupTimerState(
                    rawValue: savedTab.tabGroupData?.tabHistoryCurrentState ?? ""
                )
            )

            let tabData = TabData(
                id: savedTabUUID,
                title: savedTab.title,
                siteUrl: savedTab.url?.absoluteString ?? "",
                faviconURL: savedTab.faviconURL,
                isPrivate: savedTab.isPrivate,
                lastUsedTime: Date.fromTimestamp(Date().toTimestamp()),
                createdAtTime: Date.fromTimestamp(savedTab.createdAt ?? Date().toTimestamp()),
                tabGroupData: tabGroupData
            )

            if savedTab.isSelected {
                selectTabUUID = savedTab.screenshotUUID
            }
            tabsToMigrate.append(tabData)
        }

        let windowData = WindowData(id: windowUUID,
                                    activeTabId: selectTabUUID ?? UUID(),
                                    tabData: tabsToMigrate)

        logger.log("Tab migration completed with tab count \(windowData.tabData.count)",
                   level: .debug,
                   category: .tabs)

        if legacyTabs.count != windowData.tabData.count {
            logger.log("Something went wrong when migrating tab data",
                       level: .fatal,
                       category: .tabs)
        }

        // Save migration WindowData
        await tabDataStore.saveWindowData(window: windowData, forced: true)
        prefs.setBool(false, forKey: migrationKey)
        return windowData
    }
}
