// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common
import Shared
import TabDataStore

@MainActor
final class TabGroupManager: TabGroupMembershipLookup {
    static let didChange = Notification.Name("TabGroupManager.didChange")

    enum GroupError: Error {
        case notLoaded
        case closedWindow
        case unknownGroup
        case invalidTab
        case invalidSnapshot
        case groupOpenInAnotherWindow
    }

    private(set) var groups: [TabGroup] = []
    private(set) var isLoaded = false
    private(set) var lastPersistenceError: Error?
    private let storage: any TabGroupStorage
    private let logger: Logger
    private var savedTabs: [TabUUID: TabData] = [:]
    private var membership: [TabUUID: TabGroupID] = [:]
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
            try applySnapshot(snapshot)
            isLoaded = true
            self.loadTask = nil
            lastPersistenceError = nil
            NotificationCenter.default.post(name: Self.didChange, object: self)
        } catch {
            loadTask = nil
            lastPersistenceError = error
            throw error
        }
    }

    private func applySnapshot(_ snapshot: TabGroupSnapshot) throws {
        var availableTabs: [TabUUID: TabData] = [:]
        for tab in snapshot.tabs where !tab.isPrivate {
            availableTabs[tab.id.uuidString] = tab
        }

        var groupIDs = Set<TabGroupID>()
        var restoredGroups: [TabGroup] = []
        var restoredTabs: [TabUUID: TabData] = [:]
        var restoredMembership: [TabUUID: TabGroupID] = [:]

        for var group in snapshot.groups {
            if groupIDs.contains(group.id) { continue }
            groupIDs.insert(group.id)

            var memberIDs: [TabUUID] = []
            for tabID in group.tabIDs {
                guard let tab = availableTabs[tabID] else { throw GroupError.invalidSnapshot }
                if restoredMembership[tabID] != nil { continue }

                memberIDs.append(tabID)
                restoredTabs[tabID] = tab
                restoredMembership[tabID] = group.id
            }
            group.tabIDs = memberIDs
            restoredGroups.append(group)
        }

        groups = restoredGroups
        savedTabs = restoredTabs
        membership = restoredMembership
    }

    func groupID(for tabID: TabUUID) -> TabGroupID? {
        membership[tabID]
    }

    func savedTab(for tabID: TabUUID) -> TabData? {
        savedTabs[tabID]
    }

    func activeWindow(for groupID: TabGroupID) -> WindowUUID? {
        activeWindows[groupID]
    }

    func tabIDs(in groupID: TabGroupID) -> [TabUUID] {
        groups.first(where: { $0.id == groupID })?.tabIDs ?? []
    }

    func tabs(in groupID: TabGroupID) throws -> [TabData] {
        try requireGroup(groupID)
        return tabIDs(in: groupID).compactMap { savedTabs[$0] }
    }

    @discardableResult
    func createGroup(title: String, color: TabGroupColor = .blue, emoji: String? = nil) throws -> TabGroupID {
        guard isLoaded else { throw GroupError.notLoaded }
        var group = TabGroup(title: title, color: color)
        group.emoji = emoji
        groups.append(group)
        saveChanges()
        return group.id
    }

    func updateGroup(_ groupID: TabGroupID, title: String, color: TabGroupColor, emoji: String? = nil) throws {
        try requireGroup(groupID)
        guard let index = groups.firstIndex(where: { $0.id == groupID }) else { return }
        groups[index].title = title
        groups[index].color = color
        groups[index].emoji = emoji
        saveChanges()
    }

    @discardableResult
    func openGroup(_ groupID: TabGroupID, in windowUUID: WindowUUID) throws -> WindowUUID {
        try requireGroup(groupID)
        if let existing = activeWindows[groupID] { return existing }
        activeWindows[groupID] = windowUUID
        return windowUUID
    }

    func moveGroupsForWindowMerge(_ tabIDs: Set<TabUUID>, to windowUUID: WindowUUID) {
        guard isLoaded else { return }
        for group in groups {
            guard !group.tabIDs.isEmpty, group.tabIDs.allSatisfy({ tabIDs.contains($0) }) else { continue }
            activeWindows[group.id] = windowUUID
        }
    }

    func closeGroup(_ groupID: TabGroupID, in windowUUID: WindowUUID) {
        guard activeWindows[groupID] == windowUUID else { return }
        activeWindows[groupID] = nil
    }

    func closeWindow(_ windowUUID: WindowUUID) {
        activeWindows = activeWindows.filter { $0.value != windowUUID }
    }

    func deleteGroup(_ groupID: TabGroupID) throws {
        try requireGroup(groupID)
        for tabID in tabIDs(in: groupID) { savedTabs[tabID] = nil }
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
                savedTabs[tab.tabUUID] = tab.dataForSaving()
            }
        } else {
            for tab in moving { savedTabs[tab.tabUUID] = nil }
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
            if let window = activeWindows[groupID], window != tab.windowUUID {
                throw GroupError.groupOpenInAnotherWindow
            }
        }
    }

    func bind(_ tab: Tab) {
        guard isLoaded else { return }
        let initialGroupID = tab.isBound(to: self) ? nil : tab.groupID
        tab.bindGroupMembership(to: self)
        guard !tab.isPrivate else { return }
        if let existingGroupID = membership[tab.tabUUID] {
            _ = try? openGroup(existingGroupID, in: tab.windowUUID)
        } else if let initialGroupID {
            try? moveTab(tab, to: initialGroupID)
        }
    }

    func canRestoreTab(_ tabID: TabUUID, in windowUUID: WindowUUID) -> Bool {
        guard let groupID = membership[tabID], let window = activeWindows[groupID] else { return true }
        return window == windowUUID
    }

    func removeTab(_ tabID: TabUUID) {
        guard isLoaded, membership[tabID] != nil else { return }
        for index in groups.indices { groups[index].tabIDs.removeAll { $0 == tabID } }
        savedTabs[tabID] = nil
        rebuildMembership()
        saveChanges()
    }

    func preserveTabs(_ tabs: [TabData], in windowUUID: WindowUUID) {
        guard isLoaded else { return }
        var changed = false
        for tab in tabs where !tab.isPrivate {
            let tabID = tab.id.uuidString
            guard let groupID = membership[tabID], activeWindows[groupID] == windowUUID else { continue }
            savedTabs[tabID] = tab
            changed = true
        }
        if changed { saveChanges() }
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
        savedTabs.values.map(\.id)
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
        pendingSave = TabGroupSnapshot(groups: groups, tabs: savedTabs.values.sorted { $0.id.uuidString < $1.id.uuidString })
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

extension Tab {
    func dataForSaving() -> TabData {
        // Never persist a raw internal error-page URL as a tab's restorable siteUrl,
        // substitute the original failing URL so restoration points at the real site.
        let persistedURL: URL?
        if let url, let internalURL = InternalURL(url), internalURL.isErrorPage {
            persistedURL = internalURL.originalURLFromErrorPage
        } else {
            persistedURL = url
        }
        return TabData(id: UUID(uuidString: tabUUID) ?? UUID(),
                       title: lastTitle,
                       siteUrl: persistedURL?.absoluteString ?? lastKnownUrl?.absoluteString ?? "",
                       faviconURL: faviconURL,
                       isPrivate: isPrivate,
                       lastUsedTime: Date.fromTimestamp(lastExecutedTime),
                       createdAtTime: Date.fromTimestamp(firstCreatedTime),
                       temporaryDocumentSession: getTemporaryDocumentsSession())
    }
}
