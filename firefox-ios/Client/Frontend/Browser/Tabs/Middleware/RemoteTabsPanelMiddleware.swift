// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Storage
import Common
import Shared
import Redux

// TODO: [8188] Middlewares are currently handling actions globally. Need updates for multi-window. Forthcoming.
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
        switch action {
        case RemoteTabsPanelAction.panelDidAppear:
            self.getSyncState()
            store.dispatch(TabTrayAction.firefoxAccountChanged(self.hasSyncableAccount))
        case RemoteTabsPanelAction.refreshTabs:
            self.getSyncState()
        default:
            break
        }
    }

    // MARK: - Internal Utilities
    private func getSyncState() {
        ensureMainThread { [self] in
            guard self.hasSyncableAccount else {
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

            getCachedRemoteTabs()
        }
    }

    private func getCachedRemoteTabs() {
        profile.getCachedClientsAndTabs { result in
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
        switch notification.name {
        case .FirefoxAccountChanged,
                .ProfileDidFinishSyncing:
            getCachedRemoteTabs()
            store.dispatch(TabTrayAction.firefoxAccountChanged(hasSyncableAccount))
        default: break
        }
    }
}
