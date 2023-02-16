// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Storage
import Common

protocol JumpBackInDataAdaptor: Actor {
    func hasSyncedTabFeatureEnabled() -> Bool
    func getRecentTabData() -> [Tab]
    func getGroupsData() -> [ASGroup<Tab>]?
    func getSyncedTabData() -> JumpBackInSyncedTab?
}

protocol JumpBackInDelegate: AnyObject {
    func didLoadNewData()
}

actor JumpBackInDataAdaptorImplementation: JumpBackInDataAdaptor, FeatureFlaggable {
    // MARK: Properties

    nonisolated let notificationCenter: NotificationProtocol
    private let profile: Profile
    private let tabManager: TabManagerProtocol
    private var recentTabs: [Tab] = [Tab]()
    private var recentGroups: [ASGroup<Tab>]?
    private var mostRecentSyncedTab: JumpBackInSyncedTab?
    private var hasSyncAccount: Bool?

    private let mainQueue: DispatchQueueInterface
    private let userInitiatedQueue: DispatchQueueInterface

    weak var delegate: JumpBackInDelegate?

    // MARK: Init
    init(profile: Profile,
         tabManager: TabManagerProtocol,
         mainQueue: DispatchQueueInterface = DispatchQueue.main,
         userInitiatedQueue: DispatchQueueInterface = DispatchQueue.global(qos: DispatchQoS.userInitiated.qosClass),
         notificationCenter: NotificationProtocol = NotificationCenter.default) {
        self.profile = profile
        self.tabManager = tabManager
        self.notificationCenter = notificationCenter

        self.mainQueue = mainQueue
        self.userInitiatedQueue = userInitiatedQueue

        let notifications: [Notification.Name] = [.ShowHomepage,
                                                  .TabsTrayDidClose,
                                                  .TabsTrayDidSelectHomeTab,
                                                  .TopTabsTabClosed,
                                                  .ProfileDidFinishSyncing,
                                                  .FirefoxAccountChanged,
                                                  .TabDataUpdated]
        notifications.forEach {
            notificationCenter.addObserver(self,
                                           selector: #selector(handleNotifications),
                                           name: $0,
                                           object: nil)
        }

        Task {
            await self.updateTabsAndAccountData()
        }
    }

    deinit {
        notificationCenter.removeObserver(self)
    }

    // MARK: Public interface

    func hasSyncedTabFeatureEnabled() -> Bool {
        return featureFlags.isFeatureEnabled(.jumpBackInSyncedTab, checking: .buildOnly) && hasSyncAccount ?? false
    }

    func getRecentTabData() -> [Tab] {
        return recentTabs
    }

    func getGroupsData() -> [ASGroup<Tab>]? {
        return recentGroups
    }

    func getSyncedTabData() -> JumpBackInSyncedTab? {
        return mostRecentSyncedTab
    }

    func setDelegate(delegate: JumpBackInDelegate) {
        self.delegate = delegate
    }

    // MARK: Jump back in data

    private func updateTabsAndAccountData() async {
        hasSyncAccount = await getHasSyncAccount()
        await updateTabsData()
    }

    private func updateTabsData() async {
        recentTabs = await updateRecentTabs()
        if let remoteTabs = await updateRemoteTabs() {
            createMostRecentSyncedTab(from: remoteTabs)
        }
        recentGroups = await updateGroupsData()
        delegate?.didLoadNewData()
    }

    private func updateRecentTabs() async -> [Tab] {
        // Recent tabs need to be accessed from .main otherwise value isn't proper
        return await withCheckedContinuation { continuation in
            mainQueue.async {
                continuation.resume(returning: self.tabManager.recentlyAccessedNormalTabs)
            }
        }
    }

    private func updateGroupsData() async -> [ASGroup<Tab>]? {
        guard featureFlags.isFeatureEnabled(.tabTrayGroups, checking: .buildAndUser) else {
            return nil
        }
        return await withCheckedContinuation { continuation in
            SearchTermGroupsUtility.getTabGroups(
                with: self.profile,
                from: self.recentTabs,
                using: .orderedDescending
            ) { [weak self] groups, _ in
                continuation.resume(returning: groups)
            }
        }
    }

    // MARK: Synced tab data

    private func getHasSyncAccount() async -> Bool {
        guard featureFlags.isFeatureEnabled(.jumpBackInSyncedTab, checking: .buildOnly) else {
            return false
        }

        return await withCheckedContinuation { continuation in
            profile.hasSyncAccount { hasSync in
                continuation.resume(returning: hasSync)
            }
        }
    }

    private func updateRemoteTabs() async -> [ClientAndTabs]? {
        // Short circuit if the user is not logged in or feature not enabled
        guard hasSyncedTabFeatureEnabled() else {
            return nil
        }

        return await withCheckedContinuation { continuation in
            // Get cached tabs
            profile.getCachedClientsAndTabs { [weak self] result in
                continuation.resume(returning: result)
            }
        }
    }

    private func createMostRecentSyncedTab(from clientAndTabs: [ClientAndTabs]) {
        // filter clients for non empty desktop clients
        let desktopClientAndTabs = clientAndTabs.filter { !$0.tabs.isEmpty &&
            ClientType.fromFxAType($0.client.type) == .Desktop }

        guard !desktopClientAndTabs.isEmpty, !clientAndTabs.isEmpty else {
            mostRecentSyncedTab = nil
            return
        }

        // get most recent tab
        var mostRecentTab: (client: RemoteClient, tab: RemoteTab)?

        desktopClientAndTabs.forEach { remoteClient in
            guard let firstClient = remoteClient.tabs.first else { return }
            let mostRecentClientTab = remoteClient.tabs.reduce(firstClient, {
                                                                $0.lastUsed > $1.lastUsed ? $0 : $1 })

            if let currentMostRecentTab = mostRecentTab,
               currentMostRecentTab.tab.lastUsed < mostRecentClientTab.lastUsed {
                mostRecentTab = (client: remoteClient.client, tab: mostRecentClientTab)
            } else if mostRecentTab == nil {
                mostRecentTab = (client: remoteClient.client, tab: mostRecentClientTab)
            }
        }

        guard let mostRecentTab = mostRecentTab else {
            mostRecentSyncedTab = nil
            return
        }

        mostRecentSyncedTab = JumpBackInSyncedTab(client: mostRecentTab.client, tab: mostRecentTab.tab)
    }

    @MainActor
    @objc func handleNotifications(_ notification: Notification) {
        Task {
            switch notification.name {
            case .ShowHomepage,
                    .TabDataUpdated,
                    .TabsTrayDidClose,
                    .TabsTrayDidSelectHomeTab,
                    .TopTabsTabClosed:
                await updateTabsData()
            case .ProfileDidFinishSyncing,
                    .FirefoxAccountChanged:
                await updateTabsAndAccountData()
            default: break
            }
        }
    }
}
