// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Storage
import Common
import Shared
import Redux

import struct MozillaAppServices.Device

class RemoteTabsPanelMiddleware {
    private let profile: Profile
    var notificationCenter: NotificationProtocol

    var hasSyncableAccount: Bool {
        return profile.hasSyncableAccount()
    }

    init(profile: Profile = AppContainer.shared.resolve(),
         notificationCenter: NotificationProtocol = NotificationCenter.default) {
        self.profile = profile
        self.notificationCenter = notificationCenter
        observeNotifications()
    }

    lazy var remoteTabsPanelProvider: Middleware<AppState> = { [self] state, action in
        let uuid = action.windowUUID
        if let action = action as? RemoteTabsPanelAction {
            self.resolveRemoteTabsPanelActions(action: action, state: state)
        } else {
            self.resolveHomepageActions(action: action, state: state)
        }
    }

    // MARK: - Internal Utilities
    private func resolveRemoteTabsPanelActions(action: RemoteTabsPanelAction, state: AppState) {
        let uuid = action.windowUUID
        switch action.actionType {
        case RemoteTabsPanelActionType.panelDidAppear:
            self.getSyncState(window: uuid)
            let accountChangeAction = TabTrayAction(hasSyncableAccount: self.hasSyncableAccount,
                                                    windowUUID: uuid,
                                                    actionType: TabTrayActionType.firefoxAccountChanged)
            store.dispatch(accountChangeAction)
        case RemoteTabsPanelActionType.refreshTabs:
            self.getSyncState(window: uuid)
        case RemoteTabsPanelActionType.refreshTabsWithCache:
            self.getSyncState(window: uuid, useCache: true)
        default:
            break
        }
    }

    private func resolveHomepageActions(action: Action, state: AppState) {
        switch action.actionType {
        case HomepageActionType.viewWillAppear,
            JumpBackInActionType.fetchRemoteTabs,
            TabTrayActionType.dismissTabTray,
            TopTabsActionType.didTapNewTab,
            TopTabsActionType.didTapCloseTab:
            self.handleFetchingMostRecentRemoteTab(windowUUID: action.windowUUID)
        default:
            break
        }
    }

    private func getSyncState(window: WindowUUID, useCache: Bool = false) {
        ensureMainThread { [self] in
            guard self.hasSyncableAccount else {
                let action = RemoteTabsPanelAction(reason: .notLoggedIn,
                                                   windowUUID: window,
                                                   actionType: RemoteTabsPanelActionType.refreshDidFail)
                store.dispatch(action)
                return
            }

            let syncEnabled = (profile.prefs.boolForKey(PrefsKeys.TabSyncEnabled) == true)
            guard syncEnabled else {
                let action = RemoteTabsPanelAction(reason: .syncDisabledByUser,
                                                   windowUUID: window,
                                                   actionType: RemoteTabsPanelActionType.refreshDidFail)
                store.dispatch(action)
                return
            }

            // If above checks have succeeded, we know we can perform the tab refresh. We
            // need to update the State to .refreshing since there are implications for being
            // in the middle of a refresh (pull-to-refresh shouldn't trigger a new update etc.)
            let action = RemoteTabsPanelAction(windowUUID: window,
                                               actionType: RemoteTabsPanelActionType.refreshDidBegin)
            store.dispatch(action)

            getTabsAndDevices(window: window, useCache: useCache)
        }
    }

    private func getTabsAndDevices(window: WindowUUID, useCache: Bool = false) {
        let completion = { (result: [ClientAndTabs]?) in
            guard let clientAndTabs = result else {
                let action = RemoteTabsPanelAction(reason: .failedToSync,
                                                   windowUUID: window,
                                                   actionType: RemoteTabsPanelActionType.refreshDidFail)
                store.dispatch(action)
                return
            }
            var action: RemoteTabsPanelAction

            if let constellation = self.profile.rustFxA.accountManager?.deviceConstellation() {
                constellation.refreshState()

                action = RemoteTabsPanelAction(clientAndTabs: clientAndTabs,
                                               devices: constellation.state()?.remoteDevices,
                                               windowUUID: window,
                                               actionType: RemoteTabsPanelActionType.refreshDidSucceed)
            } else {
                action = RemoteTabsPanelAction(clientAndTabs: clientAndTabs,
                                               devices: nil,
                                               windowUUID: window,
                                               actionType: RemoteTabsPanelActionType.refreshDidSucceed)
            }
            store.dispatch(action)
        }

        if useCache {
            profile.getCachedClientsAndTabs(completion: completion)
        } else {
            profile.getClientsAndTabs(completion: completion)
        }
    }

    private func handleFetchingMostRecentRemoteTab(windowUUID: WindowUUID) {
        let completion = { (result: [ClientAndTabs]?) in
            guard let mostRecentSyncedTab = self.retrieveConfigurationForMostRecentTab(from: result) else { return }
            store.dispatch(
                RemoteTabsAction(
                    mostRecentSyncedTab: mostRecentSyncedTab,
                    windowUUID: windowUUID,
                    actionType: RemoteTabsMiddlewareActionType.fetchedMostRecentSyncedTab
                )
            )
        }
        profile.getCachedClientsAndTabs(completion: completion)
    }

    /// Retrieves the most recently used tab from a list of desktop clients tabs.
    ///
    /// This method filters the provided `clientAndTabs` list to include only desktop clients that have at least one tab.
    /// Then, it finds the most recently used tab for each client and then determines the most recent tab across all clients.
    /// If a valid tab is found, it returns a `RemoteTabConfiguration` containing the client and tab details.
    ///
    /// - Parameter clientAndTabs: An optional array of `ClientAndTabs`, representing synced clients and their tabs.
    /// - Returns: A `RemoteTabConfiguration` containing the most recently used tab’s details,
    /// or `nil` if no valid tab exists.
    private func retrieveConfigurationForMostRecentTab(from clientAndTabs: [ClientAndTabs]?) -> RemoteTabConfiguration? {
        let mostRecentTabsPerClient = clientAndTabs?
            .filter { !$0.tabs.isEmpty && ClientType.fromFxAType($0.client.type) == .Desktop }
            .compactMap { client in
                client.tabs
                    .max(by: { $0.lastUsed < $1.lastUsed })
                    .map { RemoteTabConfiguration(client: client.client, tab: $0) }
            }

        return mostRecentTabsPerClient?.max(by: { $0.tab.lastUsed < $1.tab.lastUsed })
    }

    // MARK: - Notifications
    private func observeNotifications() {
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self,
                                       selector: #selector(notificationReceived),
                                       name: .FirefoxAccountChanged,
                                       object: nil)
        notificationCenter.addObserver(self,
                                       selector: #selector(notificationReceived),
                                       name: .ProfileDidFinishSyncing,
                                       object: nil)
        notificationCenter.addObserver(self,
                                       selector: #selector(notificationReceived),
                                       name: .constellationStateUpdate,
                                       object: nil)
    }

    @objc
    func notificationReceived(_ notification: Notification) {
        switch notification.name {
        case .FirefoxAccountChanged,
                .ProfileDidFinishSyncing:
            // This update occurs independently of any specific window, so for now we send `.unavailable`
            // as the window UUID. Reducers responding to these types of messages need to use care not to
            // propagate that UUID in any subsequent actions or state changes.
            let accountChangeAction = TabTrayAction(hasSyncableAccount: hasSyncableAccount,
                                                    windowUUID: WindowUUID.unavailable,
                                                    actionType: TabTrayActionType.firefoxAccountChanged)
            store.dispatch(accountChangeAction)
        case .constellationStateUpdate:
            let action = RemoteTabsPanelAction(windowUUID: WindowUUID.unavailable,
                                               actionType: RemoteTabsPanelActionType.remoteDevicesChanged)
            store.dispatch(action)
        default: break
        }
    }
}
