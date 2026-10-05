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
        }
        controller.selectGroup(id: groupID)
        return tabManager.windowUUID
    }

    func closeTabs(_ tabs: [Tab]) {
        guard !tabs.isEmpty else { return }
        let selectedTabID = tabManager.selectedTab?.tabUUID
        tabManager.removeTabs(tabs)
        let normalIDs = tabManager.normalTabs.map(\.tabUUID)
        controller.reconcile(normalTabIDs: normalIDs)
        let visibleIDs = controller.visibleTabIDs(normalTabIDs: normalIDs)
        let preferredID = selectedTabID.flatMap { visibleIDs.contains($0) ? $0 : nil }
            ?? controller.preferredTabID(normalTabIDs: normalIDs)
        if let preferredID, let tab = tabManager.getTabForUUID(uuid: preferredID) {
            tabManager.selectTab(tab)
            controller.recordSelectedTab(preferredID, normalTabIDs: normalIDs)
        } else {
            let tab = tabManager.addTab(nil, isPrivate: false, groupID: controller.state.selectedGroupID)
            tabManager.selectTab(tab)
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
