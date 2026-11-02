// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common

struct TabGroupsWindowState: Equatable {
    var groups: [TabGroup]
    var selectedGroupID: TabGroupID?
    var lastSelectedUngroupedTabID: TabUUID?
}

@MainActor
final class TabGroupsController: NSObject {
    let groupManager: TabGroupManager
    let windowUUID: WindowUUID
    weak var tabManager: TabManager?
    private var selectedGroupID: TabGroupID?
    private var lastSelectedTabs: [TabGroupID: TabUUID] = [:]
    private var lastSelectedUngroupedTabID: TabUUID?
    private var isUpdating = false
    var onChange: ((TabGroupsWindowState) -> Void)?

    var state: TabGroupsWindowState {
        let selected = selectedGroupID.flatMap { id in
            groupManager.activeWindow(for: id) == windowUUID ? id : nil
        }
        return TabGroupsWindowState(groups: groupManager.groups,
                                    selectedGroupID: selected,
                                    lastSelectedUngroupedTabID: lastSelectedUngroupedTabID)
    }

    init(groupManager: TabGroupManager, windowUUID: WindowUUID, tabManager: TabManager? = nil) {
        self.groupManager = groupManager
        self.windowUUID = windowUUID
        self.tabManager = tabManager
        super.init()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(groupsChanged),
                                               name: TabGroupManager.didChange,
                                               object: groupManager)
    }

    @objc private func groupsChanged() {
        guard !isUpdating else { return }
        onChange?(state)
    }

    private func update(_ operation: () throws -> Void) {
        isUpdating = true
        defer {
            isUpdating = false
            onChange?(state)
        }
        do { try operation() } catch {
            DefaultLogger.shared.log("Could not update tab group: \(error)", level: .warning, category: .tabs)
        }
    }

    @discardableResult
    func createGroup(name: String,
                     emoji: String = "🗂️",
                     color: TabGroupColor = .orange,
                     tabIDs: [TabUUID] = [],
                     normalTabIDs: [TabUUID]) -> TabGroupID? {
        let title = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let emoji = emoji.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty, !emoji.isEmpty, groupManager.isLoaded else { return nil }
        var id: TabGroupID?
        update {
            let created = try groupManager.createGroup(title: title, color: color, emoji: emoji)
            _ = try groupManager.openGroup(created, in: windowUUID)
            try groupManager.moveTabs(liveTabs(tabIDs, normalTabIDs: normalTabIDs), to: created)
            selectedGroupID = created
            id = created
        }
        return id
    }

    func updateGroup(id: TabGroupID, name: String, emoji: String, color: TabGroupColor) {
        let title = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let emoji = emoji.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty, !emoji.isEmpty else { return }
        update { try groupManager.updateGroup(id, title: title, color: color, emoji: emoji) }
    }

    func deleteGroup(id: TabGroupID) {
        guard let tabManager else { return }
        update {
            try tabManager.deleteTabGroup(id)
            if selectedGroupID == id { selectedGroupID = nil }
        }
    }

    func ungroup(id: TabGroupID) {
        guard let tabManager, groupManager.activeWindow(for: id) == windowUUID else { return }
        update {
            try groupManager.moveTabs(tabManager.normalTabs.filter { $0.groupID == id }, to: nil)
            try groupManager.deleteGroup(id)
            if selectedGroupID == id { selectedGroupID = nil }
        }
    }

    func moveGroups(fromOffsets offsets: IndexSet, toOffset destination: Int) {
        var ids = groupManager.groups.map(\.id)
        let indexes = offsets.filter { ids.indices.contains($0) }
        guard !indexes.isEmpty, (0...ids.count).contains(destination) else { return }
        let moved = indexes.map { ids[$0] }
        for index in indexes.reversed() { ids.remove(at: index) }
        ids.insert(contentsOf: moved, at: destination - indexes.filter { $0 < destination }.count)
        update { try groupManager.reorderGroups(ids) }
    }

    func selectGroup(id: TabGroupID?) {
        if let id, groupManager.activeWindow(for: id) != windowUUID { return }
        selectedGroupID = id
        onChange?(state)
    }

    func assignTab(_ tabID: TabUUID, to groupID: TabGroupID?, normalTabIDs: [TabUUID]) {
        update { try groupManager.moveTabs(liveTabs([tabID], normalTabIDs: normalTabIDs), to: groupID) }
    }

    func moveTabs(_ tabIDs: [TabUUID], to groupID: TabGroupID?, normalTabIDs: [TabUUID]) {
        let tabs = liveTabs(tabIDs, normalTabIDs: normalTabIDs)
        guard let lastTab = tabs.last else { return }
        update {
            try groupManager.moveTabs(tabs, to: groupID)
            selectedGroupID = groupID
            recordSelectedTab(lastTab.tabUUID, normalTabIDs: normalTabIDs)
        }
    }

    func reconcile(normalTabIDs: [TabUUID]) {
        lastSelectedTabs = lastSelectedTabs.filter { normalTabIDs.contains($0.value) }
        if let id = lastSelectedUngroupedTabID, !normalTabIDs.contains(id) { lastSelectedUngroupedTabID = nil }
    }

    func recordSelectedTab(_ tabID: TabUUID, normalTabIDs: [TabUUID]) {
        guard normalTabIDs.contains(tabID) else { return }
        if let id = groupManager.groupID(for: tabID) {
            lastSelectedTabs[id] = tabID
        } else {
            lastSelectedUngroupedTabID = tabID
        }
    }

    func visibleTabIDs(normalTabIDs: [TabUUID]) -> [TabUUID] {
        let selected = state.selectedGroupID
        return normalTabIDs.filter { groupManager.groupID(for: $0) == selected }
    }

    func preferredTabID(normalTabIDs: [TabUUID]) -> TabUUID? {
        let ids = visibleTabIDs(normalTabIDs: normalTabIDs)
        let preferred = state.selectedGroupID.flatMap { lastSelectedTabs[$0] } ?? lastSelectedUngroupedTabID
        return preferred.flatMap { ids.contains($0) ? $0 : nil } ?? ids.first
    }

    private func liveTabs(_ tabIDs: [TabUUID], normalTabIDs: [TabUUID]) -> [Tab] {
        let requested = Set(tabIDs)
        return tabManager?.normalTabs.filter { requested.contains($0.tabUUID) && normalTabIDs.contains($0.tabUUID) } ?? []
    }
}
