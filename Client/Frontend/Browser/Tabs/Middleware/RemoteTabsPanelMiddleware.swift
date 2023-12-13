// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Storage
import Common
import Shared
import Redux

class RemoteTabsPanelMiddleware {
    private let profile: Profile
    var notificationCenter: NotificationProtocol

    init(profile: Profile = AppContainer.shared.resolve(),
         notificationCenter: NotificationProtocol = NotificationCenter.default) {
        self.profile = profile
        self.notificationCenter = notificationCenter
        observeNotifications()
    }

    lazy var remoteTabsPanelProvider: Middleware<AppState> = { state, action in
        switch action {
        case RemoteTabsPanelAction.panelDidAppear:
            self.getSyncState()
        case RemoteTabsPanelAction.refreshTabs:
            self.getSyncState()
        default:
            break
        }
    }

    // MARK: - Internal Utilities
    private func getSyncState() {
        print("YRD getSyncState")
        ensureMainThread { [self] in
            guard profile.hasSyncableAccount() else {
                store.dispatch(RemoteTabsPanelAction.refreshDidFail(.notLoggedIn))
                return
            }

            let syncEnabled = (profile.prefs.boolForKey(PrefsKeys.TabSyncEnabled) == true)
            guard syncEnabled else {
                store.dispatch(RemoteTabsPanelAction.refreshDidFail(.syncDisabledByUser))
                return
            }

            // If above checks have succeeded, we know we can perform the tab refresh. We
            // need to update the State to .refreshing since there are implications for being
            // in the middle of a refresh (pull-to-refresh shouldn't trigger a new update etc.)
            store.dispatch(RemoteTabsPanelAction.refreshDidBegin)

            getRemoteTabs()
        }
    }

    private func getRemoteTabs() {
        print("YRD getRemoteTabs")
        profile.getCachedClientsAndTabs { result in
            guard let clientAndTabs = result else {
                store.dispatch(RemoteTabsPanelAction.refreshDidFail(.failedToSync))
                return
            }

            let results = RemoteTabsPanelCachedResults(clientAndTabs: clientAndTabs,
                                                       isUpdating: false)
            store.dispatch(RemoteTabsPanelAction.cachedTabsAvailable(results))
        }
    }

    private func getCacheResults() {
        profile.getClientsAndTabs { result in
            guard let clientAndTabs = result else {
                store.dispatch(RemoteTabsPanelAction.refreshDidFail(.failedToSync))
                return
            }
            store.dispatch(RemoteTabsPanelAction.refreshDidSucceed(clientAndTabs))
        }
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
    }

    @objc
    func notificationReceived(_ notification: Notification) {
        print("YRD firefoxAccountChanged \(notification.name)")
        switch notification.name {
        case .FirefoxAccountChanged:
            getRemoteTabs()
//        case .ProfileDidFinishSyncing:
//            getCacheResults()
        default: break
        }
    }
}
