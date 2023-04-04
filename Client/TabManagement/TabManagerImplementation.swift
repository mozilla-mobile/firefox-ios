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
        guard AppConstants.useNewTabDataStore else {
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
        guard AppConstants.useNewTabDataStore else {
            super.preserveTabs()
            return
        }

        // TODO: FXIOS-6123 Handle new save logic
    }

    override func storeChanges() {
        guard AppConstants.useNewTabDataStore else {
            super.storeChanges()
            return
        }

        // TODO: FXIOS-6123 Handle new save logic
    }

    override func selectTab(_ tab: Tab?, previous: Tab? = nil) {
        guard AppConstants.useNewTabDataStore else {
            super.selectTab(tab, previous: previous)
            return
        }

        // TODO: FXIOS-6123 Handle new select tab logic
    }
}
