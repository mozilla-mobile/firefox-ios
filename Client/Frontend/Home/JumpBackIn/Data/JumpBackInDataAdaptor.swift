// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Storage
import Common

protocol JumpBackInDataAdaptor {
    var hasSyncedTabFeatureEnabled: Bool { get }

    func getRecentTabData() -> [Tab]
    func getGroupsData() -> [ASGroup<Tab>]?
    func getSyncedTabData() -> JumpBackInSyncedTab?
}

protocol JumpBackInDelegate: AnyObject {
    func didLoadNewData()
}

class JumpBackInDataAdaptorImplementation: JumpBackInDataAdaptor, FeatureFlaggable {
    // MARK: Properties

    var notificationCenter: NotificationProtocol
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

        setupNotifications(forObserver: self, observing: [.ShowHomepage,
                                                          .TabsTrayDidClose,
                                                          .TabsTrayDidSelectHomeTab,
                                                          .TopTabsTabClosed,
                                                          .ProfileDidFinishSyncing,
                                                          .FirefoxAccountChanged,
                                                          .TabDataUpdated])

        userInitiatedQueue.async { [weak self] in
            self?.updateTabsAndAccountData()
        }
    }

    deinit {
        notificationCenter.removeObserver(self)
    }

    // MARK: Public interface

    var hasSyncedTabFeatureEnabled: Bool {
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

    // MARK: Jump back in data

    private func updateTabsAndAccountData() {
        getHasSyncAccount { [weak self] in
            self?.updateTabsData()
        }
    }

    private func updateTabsData() {
        updateTabsData { [weak self] in
            self?.delegate?.didLoadNewData()
        }

        updateRemoteTabs { [weak self] in
            self?.delegate?.didLoadNewData()
        }

        if featureFlags.isFeatureEnabled(.tabTrayGroups, checking: .buildAndUser) {
            updateGroupsData { [weak self] in
                self?.delegate?.didLoadNewData()
            }
        }
    }

    private func updateTabsData(completion: @escaping () -> Void) {
        // Recent tabs need to be accessed from .main otherwise value isn't proper
        mainQueue.async {
            self.recentTabs = self.tabManager.recentlyAccessedNormalTabs
            completion()
        }
    }

    private func updateGroupsData(completion: @escaping () -> Void) {
        SearchTermGroupsUtility.getTabGroups(
            with: self.profile,
            from: self.recentTabs,
            using: .orderedDescending
        ) { [weak self] groups, _ in
            self?.recentGroups = groups
            completion()
        }
    }

    // MARK: Synced tab data

    private func getHasSyncAccount(completion: @escaping () -> Void) {
        guard featureFlags.isFeatureEnabled(.jumpBackInSyncedTab, checking: .buildOnly) else {
            completion()
            return
        }

        profile.hasSyncAccount { hasSync in
            self.hasSyncAccount = hasSync
            completion()
        }
    }

    private func updateRemoteTabs(completion: @escaping () -> Void) {
        // Short circuit if the user is not logged in or feature not enabled
        guard hasSyncedTabFeatureEnabled else {
            mostRecentSyncedTab = nil
            completion()
            return
        }

        // Get cached tabs
        profile.getCachedClientsAndTabs { [weak self] result in
            self?.createMostRecentSyncedTab(from: result, completion: completion)
        }
    }

    private func createMostRecentSyncedTab(from clientAndTabs: [ClientAndTabs], completion: @escaping () -> Void) {
        // filter clients for non empty desktop clients
        let desktopClientAndTabs = clientAndTabs.filter { !$0.tabs.isEmpty &&
            ClientType.fromFxAType($0.client.type) == .Desktop }

        guard !desktopClientAndTabs.isEmpty, !clientAndTabs.isEmpty else {
            mostRecentSyncedTab = nil
            completion()
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
            completion()
            return
        }

        mostRecentSyncedTab = JumpBackInSyncedTab(client: mostRecentTab.client, tab: mostRecentTab.tab)
        completion()
    }
}

// MARK: - Notifiable
extension JumpBackInDataAdaptorImplementation: Notifiable {
    func handleNotifications(_ notification: Notification) {
        userInitiatedQueue.async { [weak self] in
            switch notification.name {
            case .ShowHomepage,
                    .TabDataUpdated,
                    .TabsTrayDidClose,
                    .TabsTrayDidSelectHomeTab,
                    .TopTabsTabClosed:
                self?.updateTabsData()
            case .ProfileDidFinishSyncing,
                    .FirefoxAccountChanged:
                self?.updateTabsAndAccountData()
            default: break
            }
        }
    }
}
