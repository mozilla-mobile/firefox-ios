// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Shared
import UIKit
import WebKit

typealias TabGroupID = UUID

enum TabGroupColor: String, CaseIterable, Codable {
    case blue
    case cyan
    case green
    case orange
    case pink
    case purple
    case yellow

    var uiColor: UIColor {
        switch self {
        case .blue: return UIColor(red: 0.00, green: 0.38, blue: 0.88, alpha: 1.00)
        case .cyan: return UIColor(red: 0.00, green: 0.62, blue: 0.72, alpha: 1.00)
        case .green: return UIColor(red: 0.13, green: 0.62, blue: 0.32, alpha: 1.00)
        case .orange: return UIColor(red: 0.96, green: 0.43, blue: 0.10, alpha: 1.00)
        case .pink: return UIColor(red: 0.86, green: 0.20, blue: 0.53, alpha: 1.00)
        case .purple: return UIColor(red: 0.50, green: 0.24, blue: 0.78, alpha: 1.00)
        case .yellow: return UIColor(red: 0.94, green: 0.69, blue: 0.05, alpha: 1.00)
        }
    }
}

struct TabGroup: Codable, Equatable, Identifiable {
    let id: TabGroupID
    var name: String
    var color: TabGroupColor
    var tabUUIDs: [TabUUID]

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case color
        case tabUUIDs
    }

    init(id: TabGroupID, name: String, color: TabGroupColor, tabUUIDs: [TabUUID]) {
        self.id = id
        self.name = name
        self.color = color
        self.tabUUIDs = tabUUIDs
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(TabGroupID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        color = try container.decodeIfPresent(TabGroupColor.self, forKey: .color) ?? .blue
        tabUUIDs = try container.decode([TabUUID].self, forKey: .tabUUIDs)
    }
}

@MainActor
protocol TabGroupManagerDelegate: AnyObject {
    func tabGroupManagerDidChange(_ tabGroupManager: TabGroupManaging)
}

@MainActor
protocol TabGroupManaging: AnyObject {
    var groups: [TabGroup] { get }
    var selectedGroup: TabGroup? { get }
    var contextualNormalTabs: [Tab] { get }

    func addGroupDelegate(_ delegate: TabGroupManagerDelegate)
    func removeGroupDelegate(_ delegate: TabGroupManagerDelegate)
    @discardableResult
    func createGroup(name: String, tabUUIDs: [TabUUID]) -> TabGroup
    func selectGroup(_ groupID: TabGroupID?)
    func renameGroup(_ groupID: TabGroupID, to name: String)
    func deleteGroup(_ groupID: TabGroupID)
    func closeGroup(_ groupID: TabGroupID)
    func addTabs(_ tabUUIDs: [TabUUID], to groupID: TabGroupID)
    func moveTabs(_ tabUUIDs: [TabUUID], to groupID: TabGroupID)
    func ungroupTabs(_ tabUUIDs: [TabUUID])
    func reorderContextualTabs(fromIndex: Int, toIndex: Int)
}

@MainActor
final class TabGroupManager: TabManager, TabGroupManaging {
    private struct PersistedState: Codable {
        var groups: [TabGroup]
        var selectedGroupID: TabGroupID?
    }

    private struct SelectedGroupRemovalContext {
        let groupID: TabGroupID
        let selectedTabUUID: TabUUID
        let replacementTabUUIDs: [TabUUID]
    }

    nonisolated let windowUUID: WindowUUID

    private let tabManager: TabManager
    private let prefs: Prefs
    private let groupColorProvider: () -> TabGroupColor
    private var delegates = [WeakTabManagerDelegate]()
    private var groupDelegates = [WeakTabGroupManagerDelegate]()
    private var selectedGroupID: TabGroupID?
    private var pendingGroupIDs = [TabGroupID]()

    private(set) var groups = [TabGroup]()

    var selectedGroup: TabGroup? {
        guard let selectedGroupID else { return nil }
        return groups.first { $0.id == selectedGroupID }
    }

    var contextualNormalTabs: [Tab] {
        guard let selectedGroup else { return normalTabs }
        let memberIDs = Set(selectedGroup.tabUUIDs)
        return normalTabs.filter { memberIDs.contains($0.tabUUID) }
    }

    var isRestoringTabs: Bool { tabManager.isRestoringTabs }
    var tabRestoreHasFinished: Bool { tabManager.tabRestoreHasFinished }
    var recentlyAccessedNormalTabs: [Tab] { tabManager.recentlyAccessedNormalTabs }
    var selectedTab: Tab? { tabManager.selectedTab }
    var tabs: [Tab] { tabManager.tabs }
    var normalTabs: [Tab] { tabManager.normalTabs }
    var privateTabs: [Tab] { tabManager.privateTabs }

    init(tabManager: TabManager,
         prefs: Prefs,
         groupColorProvider: @escaping () -> TabGroupColor = {
             TabGroupColor.allCases.randomElement() ?? .blue
         }) {
        self.tabManager = tabManager
        self.prefs = prefs
        self.groupColorProvider = groupColorProvider
        self.windowUUID = tabManager.windowUUID
        loadState()
        tabManager.addDelegate(self)

        if tabManager.tabRestoreHasFinished {
            reconcile()
        } else {
            AppEventQueue.wait(for: .tabRestoration(windowUUID)) { [weak self] in
                Task { @MainActor in
                    self?.reconcile()
                }
            }
        }
    }

    subscript(webView: WKWebView) -> Tab? {
        tabManager[webView]
    }

    func addDelegate(_ delegate: TabManagerDelegate) {
        delegates.append(WeakTabManagerDelegate(value: delegate))
    }

    func addGroupDelegate(_ delegate: TabGroupManagerDelegate) {
        groupDelegates.append(WeakTabGroupManagerDelegate(value: delegate))
    }

    func removeGroupDelegate(_ delegate: TabGroupManagerDelegate) {
        groupDelegates.removeAll { $0.value == nil || $0.value === delegate }
    }

    func setNavigationDelegate(_ delegate: WKNavigationDelegate) {
        tabManager.setNavigationDelegate(delegate)
    }

    func removeDelegate(_ delegate: TabManagerDelegate, completion: (() -> Void)?) {
        delegates.removeAll { $0.get() == nil || $0.get() === delegate }
        completion?()
    }

    func selectTab(_ tab: Tab?, previous: Tab?, immediatePreservation: Bool) {
        tabManager.selectTab(tab, previous: previous, immediatePreservation: immediatePreservation)
    }

    func addTabsForURLs(_ urls: [URL], zombie: Bool, shouldSelectTab: Bool, isPrivate: Bool) {
        guard !urls.isEmpty else { return }

        var lastTab: Tab?
        for url in urls {
            lastTab = addTab(URLRequest(url: url), afterTab: nil, zombie: zombie, isPrivate: isPrivate)
        }

        if shouldSelectTab {
            selectTab(lastTab)
        }
    }

    @discardableResult
    func addTab(_ request: URLRequest?, afterTab: Tab?, zombie: Bool, isPrivate: Bool) -> Tab {
        let destinationGroupID = isPrivate ? nil : selectedGroupID
        let insertionTab = afterTab ?? destinationGroupID.flatMap { tabs(in: $0).last }
        if let destinationGroupID {
            pendingGroupIDs.append(destinationGroupID)
        }
        let tab = tabManager.addTab(request,
                                    afterTab: insertionTab,
                                    zombie: zombie,
                                    isPrivate: isPrivate)

        if let destinationGroupID, pendingGroupIDs.last == destinationGroupID {
            pendingGroupIDs.removeLast()
            addTabs([tab.tabUUID], to: destinationGroupID)
        }
        return tab
    }

    func removeTab(_ tabUUID: TabUUID) {
        let context = selectedGroupRemovalContext()
        tabManager.removeTab(tabUUID)
        restoreSelectedGroupIfNeeded(context)
    }

    func removeAllTabs(isPrivateMode: Bool) {
        let context = selectedGroupRemovalContext()
        tabManager.removeAllTabs(isPrivateMode: isPrivateMode)
        restoreSelectedGroupIfNeeded(context)
    }

    func removeTabs(by urls: [URL]) {
        let context = selectedGroupRemovalContext()
        tabManager.removeTabs(by: urls)
        restoreSelectedGroupIfNeeded(context)
    }

    func removeTabs(_ tabs: [Tab]) {
        let context = selectedGroupRemovalContext()
        tabManager.removeTabs(tabs)
        restoreSelectedGroupIfNeeded(context)
    }

    func removeNormalTabsOlderThan(period: TabsDeletionPeriod, currentDate: Date) {
        let context = selectedGroupRemovalContext()
        tabManager.removeNormalTabsOlderThan(period: period, currentDate: currentDate)
        restoreSelectedGroupIfNeeded(context)
    }

    func getTabForUUID(uuid: TabUUID) -> Tab? {
        tabManager.getTabForUUID(uuid: uuid)
    }

    func getTabForURL(_ url: URL) -> Tab? {
        tabManager.getTabForURL(url)
    }

    func clearAllTabsHistory() {
        tabManager.clearAllTabsHistory()
    }

    func reorderTabs(isPrivate privateMode: Bool, fromIndex: Int, toIndex: Int) {
        tabManager.reorderTabs(isPrivate: privateMode, fromIndex: fromIndex, toIndex: toIndex)
    }

    func preserveTabs(immediate: Bool) {
        tabManager.preserveTabs(immediate: immediate)
    }

    func commitChanges() {
        tabManager.commitChanges()
    }

    func notifyCurrentTabDidFinishLoading() {
        tabManager.notifyCurrentTabDidFinishLoading()
    }

    func restoreTabs() {
        tabManager.restoreTabs()
    }

    func expireLoginAlerts() {
        tabManager.expireLoginAlerts()
    }

    func addPopupForParentTab(profile: Profile,
                              parentTab: Tab,
                              configuration: WKWebViewConfiguration) -> Tab {
        let destinationGroupID = group(containing: parentTab.tabUUID)?.id
        if let destinationGroupID {
            pendingGroupIDs.append(destinationGroupID)
        }
        let tab = tabManager.addPopupForParentTab(profile: profile,
                                                  parentTab: parentTab,
                                                  configuration: configuration)
        if let destinationGroupID, pendingGroupIDs.last == destinationGroupID {
            pendingGroupIDs.removeLast()
            addTabs([tab.tabUUID], to: destinationGroupID)
        }
        return tab
    }

    func tabDidSetScreenshot(_ tab: Tab) {
        tabManager.tabDidSetScreenshot(tab)
    }

    func offloadBackgroundWebViews() async {
        await tabManager.offloadBackgroundWebViews()
    }

    func restoreScreenshot(for tab: Tab) {
        tabManager.restoreScreenshot(for: tab)
    }

    @discardableResult
    func createGroup(name: String, tabUUIDs: [TabUUID]) -> TabGroup {
        let group = TabGroup(id: UUID(), name: name, color: groupColorProvider(), tabUUIDs: [])
        groups.append(group)
        addTabs(tabUUIDs, to: group.id)
        selectedGroupID = group.id
        saveState()
        return selectedGroup ?? group
    }

    func selectGroup(_ groupID: TabGroupID?) {
        if let groupID, groups.contains(where: { $0.id == groupID }) {
            selectedGroupID = groupID
        } else {
            selectedGroupID = nil
        }
        saveState()
    }

    func renameGroup(_ groupID: TabGroupID, to name: String) {
        guard let index = groupIndex(for: groupID) else { return }
        groups[index].name = name
        saveState()
    }

    func deleteGroup(_ groupID: TabGroupID) {
        groups.removeAll { $0.id == groupID }
        if selectedGroupID == groupID {
            selectedGroupID = nil
        }
        saveState()
    }

    func closeGroup(_ groupID: TabGroupID) {
        guard let group = group(with: groupID) else { return }
        deleteGroup(groupID)
        group.tabUUIDs.forEach { tabManager.removeTab($0) }
    }

    func addTabs(_ tabUUIDs: [TabUUID], to groupID: TabGroupID) {
        guard let destinationIndex = groupIndex(for: groupID) else { return }
        let liveNormalIDs = Set(normalTabs.map(\.tabUUID))
        let validIDs = tabUUIDs.filter { liveNormalIDs.contains($0) }
        guard !validIDs.isEmpty else { return }

        let movingIDs = Set(validIDs)
        for index in groups.indices where index != destinationIndex {
            groups[index].tabUUIDs.removeAll { movingIDs.contains($0) }
        }

        let existingIDs = Set(groups[destinationIndex].tabUUIDs)
        groups[destinationIndex].tabUUIDs.append(contentsOf: validIDs.filter { !existingIDs.contains($0) })
        saveState()
    }

    func moveTabs(_ tabUUIDs: [TabUUID], to groupID: TabGroupID) {
        addTabs(tabUUIDs, to: groupID)
    }

    func ungroupTabs(_ tabUUIDs: [TabUUID]) {
        let tabIDs = Set(tabUUIDs)
        groups.indices.forEach { index in
            groups[index].tabUUIDs.removeAll { tabIDs.contains($0) }
        }
        saveState()
    }

    func reorderContextualTabs(fromIndex: Int, toIndex: Int) {
        let contextualTabs = contextualNormalTabs
        guard contextualTabs.indices.contains(fromIndex), contextualTabs.indices.contains(toIndex),
              let globalFromIndex = normalTabs.firstIndex(of: contextualTabs[fromIndex]),
              let globalToIndex = normalTabs.firstIndex(of: contextualTabs[toIndex]) else { return }

        tabManager.reorderTabs(isPrivate: false, fromIndex: globalFromIndex, toIndex: globalToIndex)
    }

    private var storageKey: String {
        "tabGroups.\(windowUUID.uuidString)"
    }

    private func groupIndex(for groupID: TabGroupID) -> Int? {
        groups.firstIndex { $0.id == groupID }
    }

    private func group(with groupID: TabGroupID) -> TabGroup? {
        groups.first { $0.id == groupID }
    }

    private func group(containing tabUUID: TabUUID) -> TabGroup? {
        groups.first { $0.tabUUIDs.contains(tabUUID) }
    }

    private func tabs(in groupID: TabGroupID) -> [Tab] {
        guard let group = group(with: groupID) else { return [] }
        let memberIDs = Set(group.tabUUIDs)
        return normalTabs.filter { memberIDs.contains($0.tabUUID) }
    }

    private func selectedGroupRemovalContext() -> SelectedGroupRemovalContext? {
        guard let selectedGroup,
              let selectedTab,
              let selectedIndex = tabs(in: selectedGroup.id).firstIndex(of: selectedTab) else { return nil }
        let groupTabUUIDs = tabs(in: selectedGroup.id).map(\.tabUUID)
        let followingTabUUIDs = groupTabUUIDs.dropFirst(selectedIndex + 1)
        let precedingTabUUIDs = groupTabUUIDs.prefix(selectedIndex).reversed()
        return SelectedGroupRemovalContext(
            groupID: selectedGroup.id,
            selectedTabUUID: selectedTab.tabUUID,
            replacementTabUUIDs: Array(followingTabUUIDs) + Array(precedingTabUUIDs)
        )
    }

    private func restoreSelectedGroupIfNeeded(_ context: SelectedGroupRemovalContext?) {
        guard let context,
              getTabForUUID(uuid: context.selectedTabUUID) == nil,
              let group = group(with: context.groupID) else { return }
        let groupTabUUIDs = Set(group.tabUUIDs)
        if let selectedTab, groupTabUUIDs.contains(selectedTab.tabUUID) {
            return
        }
        guard let replacementTabUUID = context.replacementTabUUIDs.first(where: groupTabUUIDs.contains),
              let replacementTab = getTabForUUID(uuid: replacementTabUUID) else {
            deleteGroup(context.groupID)
            return
        }
        tabManager.selectTab(replacementTab)
    }

    private func removeMembership(for tabUUID: TabUUID) {
        guard let groupIndex = groups.firstIndex(where: { $0.tabUUIDs.contains(tabUUID) }) else { return }
        groups[groupIndex].tabUUIDs.removeAll { $0 == tabUUID }
        if groups[groupIndex].tabUUIDs.isEmpty {
            let groupID = groups[groupIndex].id
            groups.remove(at: groupIndex)
            if selectedGroupID == groupID {
                selectedGroupID = nil
            }
        }
        saveState()
    }

    private func loadState() {
        guard let data: Data = prefs.objectForKey(storageKey),
              let state = try? JSONDecoder().decode(PersistedState.self, from: data) else { return }
        groups = state.groups
        selectedGroupID = state.selectedGroupID
    }

    private func saveState() {
        let state = PersistedState(groups: groups, selectedGroupID: selectedGroupID)
        guard let data = try? JSONEncoder().encode(state) else { return }
        prefs.setObject(data, forKey: storageKey)
        groupDelegates.forEach { $0.value?.tabGroupManagerDidChange(self) }
    }

    private func reconcile() {
        let liveNormalIDs = Set(normalTabs.map(\.tabUUID))
        var claimedIDs = Set<TabUUID>()

        for index in groups.indices {
            groups[index].tabUUIDs = groups[index].tabUUIDs.filter {
                liveNormalIDs.contains($0) && claimedIDs.insert($0).inserted
            }
        }

        if let selectedTab,
           let groupID = group(containing: selectedTab.tabUUID)?.id {
            selectedGroupID = groupID
        } else {
            selectedGroupID = nil
        }
        saveState()
    }
}

private final class WeakTabGroupManagerDelegate {
    weak var value: TabGroupManagerDelegate?

    init(value: TabGroupManagerDelegate) {
        self.value = value
    }
}

extension TabGroupManager: TabManagerDelegate {
    func tabManager(_ tabManager: TabManager,
                    didSelectedTabChange selectedTab: Tab,
                    previousTab: Tab?,
                    isRestoring: Bool) {
        if !isRestoring {
            selectedGroupID = group(containing: selectedTab.tabUUID)?.id
            saveState()
        }
        delegates.forEach {
            $0.get()?.tabManager(self,
                                didSelectedTabChange: selectedTab,
                                previousTab: previousTab,
                                isRestoring: isRestoring)
        }
    }

    func tabManager(_ tabManager: TabManager,
                    didAddTab tab: Tab,
                    placeNextToParentTab: Bool,
                    isRestoring: Bool) {
        if !isRestoring, !tab.isPrivate {
            let destinationGroupID = pendingGroupIDs.popLast() ?? selectedGroupID
            if let destinationGroupID {
                addTabs([tab.tabUUID], to: destinationGroupID)
            }
        }
        delegates.forEach {
            $0.get()?.tabManager(self,
                                didAddTab: tab,
                                placeNextToParentTab: placeNextToParentTab,
                                isRestoring: isRestoring)
        }
    }

    func tabManager(_ tabManager: TabManager, didRemoveTab tab: Tab, isRestoring: Bool) {
        removeMembership(for: tab.tabUUID)
        delegates.forEach {
            $0.get()?.tabManager(self, didRemoveTab: tab, isRestoring: isRestoring)
        }
    }

    func tabManagerDidRestoreTabs(_ tabManager: TabManager) {
        reconcile()
        delegates.forEach { $0.get()?.tabManagerDidRestoreTabs(self) }
    }

    func tabManagerDidAddTabs(_ tabManager: TabManager) {
        delegates.forEach { $0.get()?.tabManagerDidAddTabs(self) }
    }

    func tabManagerDidRemoveAllTabs(_ tabManager: TabManager, toast: ButtonToast?) {
        delegates.forEach { $0.get()?.tabManagerDidRemoveAllTabs(self, toast: toast) }
    }

    func tabManagerUpdateCount() {
        delegates.forEach { $0.get()?.tabManagerUpdateCount() }
    }

    func tabManagerTabDidFinishLoading() {
        delegates.forEach { $0.get()?.tabManagerTabDidFinishLoading() }
    }
}

extension TabGroupManager: WindowSimpleTabsProvider {
    func windowSimpleTabs() -> [TabUUID: SimpleTab] {
        guard let provider = tabManager as? WindowSimpleTabsProvider else { return [:] }
        return provider.windowSimpleTabs()
    }
}
