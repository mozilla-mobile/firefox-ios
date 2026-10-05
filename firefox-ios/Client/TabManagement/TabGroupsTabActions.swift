// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common

@MainActor
struct TabGroupsTabActions {
    let controller: TabGroupsController
    let tabManager: TabManager

    func openGroup(_ groupID: TabGroupID?) async throws -> WindowUUID {
        if let groupID {
            let host = try await tabManager.openTabGroup(groupID)
            guard host == tabManager.windowUUID else { return host }
        } else {
            try await controller.groupManager.restore()
            tabManager.normalTabs.forEach { controller.groupManager.bind($0) }
        }
        controller.selectGroup(id: groupID)
        selectVisibleTab()
        return tabManager.windowUUID
    }

    func closeTabs(_ tabs: [Tab]) {
        guard !tabs.isEmpty else { return }
        let selectedTab = tabManager.selectedTab
        let visibleIDs = controller.visibleTabIDs(normalTabIDs: tabManager.normalTabs.map(\.tabUUID))
        var preferredIDs = [selectedTab?.tabUUID, selectedTab?.parent?.tabUUID].compactMap { $0 }
        if let selectedTab, let index = visibleIDs.firstIndex(of: selectedTab.tabUUID) {
            preferredIDs += visibleIDs.dropFirst(index + 1)
            preferredIDs += visibleIDs.prefix(index).reversed()
        }
        tabManager.removeTabs(tabs)
        if let selectedTab, selectedTab.isPrivate,
           let survivingTab = tabManager.getTabForUUID(uuid: selectedTab.tabUUID) {
            controller.reconcile(normalTabIDs: tabManager.normalTabs.map(\.tabUUID))
            tabManager.selectTab(survivingTab, previous: selectedTab)
            return
        }
        selectVisibleTab(preferredIDs: preferredIDs, previousTab: selectedTab)
    }

    private func selectVisibleTab(preferredIDs: [TabUUID] = [], previousTab: Tab? = nil) {
        let normalIDs = tabManager.normalTabs.map(\.tabUUID)
        controller.reconcile(normalTabIDs: normalIDs)
        let visibleIDs = Set(controller.visibleTabIDs(normalTabIDs: normalIDs))
        let preferredID = preferredIDs.first { visibleIDs.contains($0) }
            ?? controller.preferredTabID(normalTabIDs: normalIDs)
        if let preferredID, let tab = tabManager.getTabForUUID(uuid: preferredID) {
            tabManager.selectTab(tab, previous: previousTab)
            controller.recordSelectedTab(preferredID, normalTabIDs: normalIDs)
        } else {
            let tab = tabManager.addTab(nil, isPrivate: false, groupID: controller.state.selectedGroupID)
            tabManager.selectTab(tab, previous: previousTab)
            controller.recordSelectedTab(tab.tabUUID, normalTabIDs: tabManager.normalTabs.map(\.tabUUID))
        }
    }

    func moveTab(_ tabID: TabUUID, to groupID: UUID?) {
        let normalIDs = tabManager.normalTabs.map(\.tabUUID)
        if tabManager.selectedTab?.tabUUID == tabID {
            controller.moveTabs([tabID], to: groupID, normalTabIDs: normalIDs)
            if let tab = tabManager.getTabForUUID(uuid: tabID) {
                tabManager.selectTab(tab)
            }
        } else {
            controller.assignTab(tabID, to: groupID, normalTabIDs: normalIDs)
        }
    }
}
