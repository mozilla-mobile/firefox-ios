// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import TabDataStore
import Storage
import Common
import Shared

// This class subclasses the legacy tab manager temporarily so we can
// gradually migrate to the new system
class TabManagerImplementation: LegacyTabManager {
    let tabDataStore: TabDataStore

    init(profile: Profile,
         imageStore: DiskImageStore?,
         logger: Logger = DefaultLogger.shared,
         tabDataStore: TabDataStore = DefaultTabDataStore()) {
        self.tabDataStore = tabDataStore
        super.init(profile: profile, imageStore: imageStore)
    }

    // MARK: - Restore tabs

    override func restoreTabs(_ forced: Bool = false) {
        guard shouldUseNewTabStore() else {
            super.restoreTabs(forced)
            return
        }

        guard !isRestoringTabs else { return }

        // TODO: FXIOS-6112 Handle debug settings and UITests

        if forced {
            tabs = [Tab]()
        }

        isRestoringTabs = true
        Task {
            guard let windowData = await self.tabDataStore.fetchTabData() else {
                // Always make sure there is a single normal tab
                self.generateEmptyTab()
                return
            }

            await self.generateTabs(from: windowData)

            for delegate in self.delegates {
                delegate.get()?.tabManagerDidRestoreTabs(self)
            }

            self.isRestoringTabs = false
        }
    }

    /// Creates the webview so needs to live on the main thread
    @MainActor
    private func generateTabs(from windowData: WindowData) async {
        for tabData in windowData.tabData {
            let newTab = addTab(flushToDisk: false, zombie: true, isPrivate: tabData.isPrivate)
            newTab.url = URL(string: tabData.siteUrl)
            newTab.lastTitle = tabData.title
            newTab.tabUUID = tabData.id.uuidString
            newTab.screenshotUUID = tabData.id
            newTab.firstCreatedTime = tabData.createdAtTime.toTimestamp()
            newTab.sessionData = LegacySessionData(currentPage: 0,
                                                   urls: [],
                                                   lastUsedTime: tabData.lastUsedTime.toTimestamp())
            let groupData = LegacyTabGroupData(searchTerm: tabData.tabGroupData?.searchTerm ?? "",
                                               searchUrl: tabData.tabGroupData?.searchUrl ?? "",
                                               nextReferralUrl: tabData.tabGroupData?.nextUrl ?? "",
                                               tabHistoryCurrentState: tabData.tabGroupData?.tabHistoryCurrentState?.rawValue ?? "")
            newTab.metadataManager?.tabGroupData = groupData

            if windowData.activeTabId == tabData.id {
                selectTab(newTab)
            }
        }
    }

    private func generateEmptyTab() {
        let newTab = addTab()
        selectTab(newTab)
    }

    // MARK: - Save tabs

    override func preserveTabs() {
        // For now we want to continue writing to both data stores so that we can revert to the old system if needed
        super.preserveTabs()
        guard shouldUseNewTabStore() else {
            return
        }

        Task {
            // This value should never be nil but we need to still treat it as if it can be nil until the old code is removed
            let activeTabID = UUID(uuidString: self.selectedTab?.tabUUID ?? "") ?? UUID()
            let windowData = WindowData(activeTabId: activeTabID,
                                        tabData: self.generateTabDataForSaving())
            await tabDataStore.saveTabData(window: windowData)
        }
    }

    private func generateTabDataForSaving() -> [TabData] {
        let tabData = tabs.map { tab in
            let oldTabGroupData = tab.metadataManager?.tabGroupData
            let state = TabGroupTimerState(rawValue: oldTabGroupData?.tabHistoryCurrentState ?? "")
            let groupData = TabGroupData(searchTerm: oldTabGroupData?.tabAssociatedSearchTerm,
                                         searchUrl: oldTabGroupData?.tabAssociatedSearchUrl,
                                         nextUrl: oldTabGroupData?.tabAssociatedNextUrl,
                                         tabHistoryCurrentState: state)
            return TabData(id: UUID(uuidString: tab.tabUUID) ?? UUID(),
                           title: tab.title ?? tab.lastTitle,
                           siteUrl: tab.url?.absoluteString ?? "",
                           faviconURL: tab.faviconURL,
                           isPrivate: tab.isPrivate,
                           lastUsedTime: Date.fromTimestamp(tab.sessionData?.lastUsedTime ?? 0),
                           createdAtTime: Date.fromTimestamp(tab.firstCreatedTime ?? 0),
                           tabGroupData: groupData)
        }
        return tabData
    }

    override func storeChanges() {
        guard shouldUseNewTabStore() else {
            super.storeChanges()
            return
        }

        saveTabs(toProfile: profile, normalTabs)
        preserveTabs()
    }

    private func shouldUseNewTabStore() -> Bool {
        if #available(iOS 15, *),
            AppConstants.useNewTabDataStore {
            return true
        }
        return false
    }
}
