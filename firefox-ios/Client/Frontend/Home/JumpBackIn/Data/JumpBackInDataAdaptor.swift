// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Storage
import Common

protocol JumpBackInDataAdaptor: Actor {
    func hasSyncedTabFeatureEnabled() -> Bool
    func getRecentTabData() -> [Tab]
    func getSyncedTabData() -> JumpBackInSyncedTab?
}

protocol JumpBackInDelegate: AnyObject {
    func didLoadNewData()
}

actor JumpBackInDataAdaptorImplementation: JumpBackInDataAdaptor, FeatureFlaggable {
    // MARK: Properties

    nonisolated let notificationCenter: NotificationProtocol
    private let profile: Profile
    private let tabManager: TabManager
    private var recentTabs = [Tab]()
    private var recentGroups: [ASGroup<Tab>]?
    private var mostRecentSyncedTab: JumpBackInSyncedTab?
    private var hasSyncAccount: Bool?

    private let mainQueue: DispatchQueueInterface

    weak var delegate: JumpBackInDelegate?

    // MARK: Init
    init(profile: Profile,
         tabManager: TabManager,
         mainQueue: DispatchQueueInterface = DispatchQueue.main,
         notificationCenter: NotificationProtocol = NotificationCenter.default) {
        self.profile = profile
        self.tabManager = tabManager
        self.notificationCenter = notificationCenter

        self.mainQueue = mainQueue

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
        return hasSyncAccount ?? false
    }

    func getRecentTabData() -> [Tab] {
        return recentTabs
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
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                let recentTabs = await self.updateRecentTabs()
                await self.setRecentTabs(recentTabs: recentTabs)
            }
            group.addTask {
                if let remoteTabs = await self.updateRemoteTabs() {
                    await self.createMostRecentSyncedTab(from: remoteTabs)
                }
            }
        }
        delegate?.didLoadNewData()
    }

    private func setRecentTabs(recentTabs: [Tab]) {
        self.recentTabs = recentTabs
    }

    private func updateRecentTabs() async -> [Tab] {
        // Recent tabs need to be accessed from .main otherwise value isn't proper
        return await withCheckedContinuation { continuation in
            mainQueue.async {
                    let recentTabs = self.tabManager.recentlyAccessedNormalTabs
                    continuation.resume(returning: recentTabs)
            }
        }
    }

    // MARK: Synced tab data

    private func getHasSyncAccount() async -> Bool {
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
            profile.getCachedClientsAndTabs { result in
                continuation.resume(returning: result ?? [])
            }
        }
    }

    private func createMostRecentSyncedTab(from clientAndTabs: [ClientAndTabs]) {
        // filter clients for non empty desktop clients
        let desktopClientAndTabs = clientAndTabs.filter { !$0.tabs.isEmpty &&
            ClientType.fromFxAType($0.client.type) == .Desktop
        }

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
    @objc
    func handleNotifications(_ notification: Notification) {
        switch notification.name {
        case .ShowHomepage,
                .TabDataUpdated,
                .TabsTrayDidClose,
                .TabsTrayDidSelectHomeTab,
                .TopTabsTabClosed:
            guard let uuid = notification.windowUUID,
                  uuid == tabManager.windowUUID
            else { return }
            Task { await updateTabsData() }
        case .ProfileDidFinishSyncing,
                .FirefoxAccountChanged:
            Task { await updateTabsAndAccountData() }
        default: break
        }
    }
}
