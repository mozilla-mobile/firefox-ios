// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common

@MainActor
protocol TabGroupMembershipLookup: AnyObject {
    func groupID(for tabID: TabUUID) -> TabGroupID?
    func activeWindow(for groupID: TabGroupID) -> WindowUUID?
}

@MainActor
final class TabGroupManager: TabGroupMembershipLookup {
    static let didChange = Notification.Name("TabGroupManager.didChange")

    enum GroupError: Error {
        case notLoaded
        case closedWindow
        case unknownGroup
        case invalidTab
        case tabsNotLoaded
        case groupOpenInAnotherWindow
    }

    private(set) var groups: [TabGroup] = []
    private(set) var isLoaded = false
    private(set) var lastPersistenceError: Error?
    private let storage: any TabGroupStorage
    private let logger: Logger
    private var membership: [TabUUID: TabGroupID] = [:]
    private var pendingRemovedTabIDs = Set<TabUUID>()
    private var activeWindows: [TabGroupID: WindowUUID] = [:]
    private var loadTask: Task<TabGroupSnapshot, Error>?
    private var saveTask: Task<Void, Error>?
    private var pendingSave: TabGroupSnapshot?

    init(storage: any TabGroupStorage, logger: Logger = DefaultLogger.shared) {
        self.storage = storage
        self.logger = logger
    }

    func restore() async throws {
        guard !isLoaded else { return }
        if loadTask == nil {
            let storage = storage
            loadTask = Task { try await storage.load() }
        }
        do {
            guard let loadTask else { return }
            let snapshot = try await loadTask.value
            guard !isLoaded else { return }
            applySnapshot(snapshot)
            isLoaded = true
            self.loadTask = nil
            lastPersistenceError = nil
            for tabID in pendingRemovedTabIDs { removeTab(tabID) }
            pendingRemovedTabIDs.removeAll()
            NotificationCenter.default.post(name: Self.didChange, object: self)
        } catch {
            loadTask = nil
            lastPersistenceError = error
            throw error
        }
    }

    private func applySnapshot(_ snapshot: TabGroupSnapshot) {
        var groupIDs = Set<TabGroupID>()
        var restoredGroups: [TabGroup] = []
        var restoredMembership: [TabUUID: TabGroupID] = [:]

        for var group in snapshot.groups {
            if groupIDs.contains(group.id) { continue }
            groupIDs.insert(group.id)

            var memberIDs: [TabUUID] = []
            for tabID in group.tabIDs {
                if restoredMembership[tabID] != nil { continue }
                memberIDs.append(tabID)
                restoredMembership[tabID] = group.id
            }
            group.tabIDs = memberIDs
            restoredGroups.append(group)
        }

        groups = restoredGroups
        membership = restoredMembership
    }

    func groupID(for tabID: TabUUID) -> TabGroupID? {
        membership[tabID]
    }

    func activeWindow(for groupID: TabGroupID) -> WindowUUID? {
        activeWindows[groupID]
    }

    func tabIDs(in groupID: TabGroupID) -> [TabUUID] {
        groups.first(where: { $0.id == groupID })?.tabIDs ?? []
    }

    @discardableResult
    func createGroup(
        title: String,
        color: CodableColor = CodableColor(red: 0.20, green: 0.44, blue: 0.90),
        icon: TabGroupIcon = .sfSymbol("rectangle.portrait.on.rectangle.portrait.angled.fill")
    ) throws -> TabGroupID {
        guard isLoaded else { throw GroupError.notLoaded }
        let group = TabGroup(title: title, color: color, icon: icon)
        groups.append(group)
        saveChanges()
        return group.id
    }

    func updateGroup(_ groupID: TabGroupID,
                     title: String,
                     color: CodableColor,
                     icon: TabGroupIcon = .sfSymbol("rectangle.portrait.on.rectangle.portrait.angled.fill")) throws {
        try requireGroup(groupID)
        guard let index = groups.firstIndex(where: { $0.id == groupID }) else { return }
        groups[index].title = title
        groups[index].color = color
        groups[index].icon = icon
        saveChanges()
    }

    @discardableResult
    func openGroup(_ groupID: TabGroupID, in windowUUID: WindowUUID) throws -> WindowUUID {
        try requireGroup(groupID)
        if let existing = activeWindows[groupID] { return existing }
        guard tabIDs(in: groupID).isEmpty else { throw GroupError.tabsNotLoaded }
        activeWindows[groupID] = windowUUID
        return windowUUID
    }

    func moveGroupsForWindowMerge(_ tabIDs: Set<TabUUID>, to windowUUID: WindowUUID) {
        guard isLoaded else { return }
        let movedGroups = Set(tabIDs.compactMap { membership[$0] })
        for groupID in movedGroups {
            activeWindows[groupID] = windowUUID
        }
    }

    func closeWindow(_ windowUUID: WindowUUID) {
        activeWindows = activeWindows.filter { $0.value != windowUUID }
    }

    func deleteGroup(_ groupID: TabGroupID) throws {
        try requireGroup(groupID)
        groups.removeAll { $0.id == groupID }
        activeWindows[groupID] = nil
        rebuildMembership()
        saveChanges()
    }

    func reorderGroups(_ groupIDs: [TabGroupID]) throws {
        guard isLoaded else { throw GroupError.notLoaded }
        guard groupIDs.count == groups.count, Set(groupIDs) == Set(groups.map(\.id)) else { return }
        let byID = Dictionary(uniqueKeysWithValues: groups.map { ($0.id, $0) })
        groups = groupIDs.compactMap { byID[$0] }
        saveChanges()
    }

    func moveTab(_ tab: Tab, to groupID: TabGroupID?) throws {
        try moveTabs([tab], to: groupID)
    }

    func moveTabs(_ tabs: [Tab], to groupID: TabGroupID?) throws {
        guard Set(tabs.map(\.windowUUID)).count <= 1 else { throw GroupError.invalidTab }
        for tab in tabs { try validateMove(tab, to: groupID) }
        var seenIDs = Set<TabUUID>()
        var moving: [Tab] = []
        for tab in tabs {
            if seenIDs.contains(tab.tabUUID) || membership[tab.tabUUID] == groupID { continue }
            seenIDs.insert(tab.tabUUID)
            moving.append(tab)
        }
        guard !moving.isEmpty else { return }
        let movingIDs = Set(moving.map(\.tabUUID))
        for index in groups.indices { groups[index].tabIDs.removeAll { movingIDs.contains($0) } }
        if let groupID, let index = groups.firstIndex(where: { $0.id == groupID }) {
            activeWindows[groupID] = moving[0].windowUUID
            for tab in moving {
                groups[index].tabIDs.append(tab.tabUUID)
            }
        }
        rebuildMembership()
        saveChanges()
    }

    private func validateMove(_ tab: Tab, to groupID: TabGroupID?) throws {
        guard isLoaded else { throw GroupError.notLoaded }
        guard !tab.isPrivate, tab.isBound(to: self), UUID(uuidString: tab.tabUUID) != nil else {
            throw GroupError.invalidTab
        }
        if let currentGroup = membership[tab.tabUUID],
           activeWindows[currentGroup] != tab.windowUUID {
            throw GroupError.invalidTab
        }
        if let groupID {
            try requireGroup(groupID)
            if let window = activeWindows[groupID] {
                guard window == tab.windowUUID else { throw GroupError.groupOpenInAnotherWindow }
            } else if !tabIDs(in: groupID).isEmpty {
                throw GroupError.tabsNotLoaded
            }
        }
    }

    func bind(_ tab: Tab) {
        guard isLoaded else { return }
        let initialGroupID = tab.isBound(to: self) ? nil : tab.groupID
        tab.bindGroupMembership(to: self)
        guard !tab.isPrivate else {
            removeTab(tab.tabUUID)
            return
        }
        if let existingGroupID = membership[tab.tabUUID] {
            if activeWindows[existingGroupID] == nil { activeWindows[existingGroupID] = tab.windowUUID }
        } else if let initialGroupID {
            try? moveTab(tab, to: initialGroupID)
        }
    }

    func canRestoreTab(_ tabID: TabUUID, in windowUUID: WindowUUID) -> Bool {
        guard let groupID = membership[tabID], let window = activeWindows[groupID] else { return true }
        return window == windowUUID
    }

    func removeTab(_ tabID: TabUUID) {
        guard isLoaded else {
            pendingRemovedTabIDs.insert(tabID)
            return
        }
        guard membership[tabID] != nil else { return }
        for index in groups.indices { groups[index].tabIDs.removeAll { $0 == tabID } }
        rebuildMembership()
        saveChanges()
    }

    func reorderTabs(_ tabIDs: [TabUUID], in windowUUID: WindowUUID) {
        guard isLoaded else { return }
        var changed = false
        for index in groups.indices where activeWindows[groups[index].id] == windowUUID {
            let members = Set(groups[index].tabIDs)
            let orderedIDs = tabIDs.filter { members.contains($0) }
            guard Set(orderedIDs) == members, orderedIDs != groups[index].tabIDs else { continue }
            groups[index].tabIDs = orderedIDs
            changed = true
        }
        if changed { saveChanges() }
    }

    var persistedTabIDs: [UUID] {
        groups.flatMap(\.tabIDs).compactMap(UUID.init(uuidString:))
    }

    func flush() async throws {
        if saveTask == nil, pendingSave != nil { startSaveTask() }
        try await saveTask?.value
    }

    private func requireGroup(_ groupID: TabGroupID) throws {
        guard isLoaded else { throw GroupError.notLoaded }
        guard groups.contains(where: { $0.id == groupID }) else { throw GroupError.unknownGroup }
    }

    private func rebuildMembership() {
        membership = [:]
        for group in groups {
            for tabID in group.tabIDs { membership[tabID] = group.id }
        }
    }

    private func saveChanges() {
        NotificationCenter.default.post(name: Self.didChange, object: self)
        pendingSave = TabGroupSnapshot(groups: groups)
        if saveTask == nil { startSaveTask() }
    }

    private func startSaveTask() {
        saveTask = Task { [weak self] in
            guard let self else { return }
            while let snapshot = pendingSave {
                pendingSave = nil
                do {
                    try await storage.save(snapshot)
                } catch {
                    pendingSave = pendingSave ?? snapshot
                    lastPersistenceError = error
                    saveTask = nil
                    logger.log("Could not save tab groups: \(error)", level: .warning, category: .tabs)
                    throw error
                }
            }
            lastPersistenceError = nil
            saveTask = nil
        }
    }
}
