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
        switch action {
        case RemoteTabsPanelAction.panelDidAppear:
            self.getSyncState(window: uuid)
            let context = HasSyncableAccountContext(hasSyncableAccount: self.hasSyncableAccount, windowUUID: uuid)
            store.dispatch(TabTrayAction.firefoxAccountChanged(context))
        case RemoteTabsPanelAction.refreshTabs:
            self.getSyncState(window: uuid)
        default:
            break
        }
    }

    // MARK: - Internal Utilities
    private func getSyncState(window: WindowUUID) {
        ensureMainThread { [self] in
            guard self.hasSyncableAccount else {
                let context = RemoteTabsRefreshDidFailContext(reason: .notLoggedIn, windowUUID: window)
                store.dispatch(RemoteTabsPanelAction.refreshDidFail(context))
                return
            }

            let syncEnabled = (profile.prefs.boolForKey(PrefsKeys.TabSyncEnabled) == true)
            guard syncEnabled else {
                let context = RemoteTabsRefreshDidFailContext(reason: .syncDisabledByUser, windowUUID: window)
                store.dispatch(RemoteTabsPanelAction.refreshDidFail(context))
                return
            }

            // If above checks have succeeded, we know we can perform the tab refresh. We
            // need to update the State to .refreshing since there are implications for being
            // in the middle of a refresh (pull-to-refresh shouldn't trigger a new update etc.)
            store.dispatch(RemoteTabsPanelAction.refreshDidBegin(window.context))

            getCachedRemoteTabs(window: window)
        }
    }

    private func getCachedRemoteTabs(window: WindowUUID) {
        profile.getCachedClientsAndTabs { result in
            guard let clientAndTabs = result else {
                let context = RemoteTabsRefreshDidFailContext(reason: .failedToSync, windowUUID: window)
                store.dispatch(RemoteTabsPanelAction.refreshDidFail(context))
                return
            }

            let context = RemoteTabsRefreshSuccessContext(clientAndTabs: clientAndTabs, windowUUID: window)
            store.dispatch(RemoteTabsPanelAction.refreshDidSucceed(context))
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
            // This update occurs independently of any specific window, so for now we send `.unavailable`
            // as the window UUID. Aspects of this are TBD and part of ongoing MW/Redux refactors.
            // TODO: [8188] Revisit UUID here to determine ideal handling.
            let uuid = WindowUUID.unavailable
            let context = HasSyncableAccountContext(hasSyncableAccount: hasSyncableAccount, windowUUID: uuid)
            getCachedRemoteTabs(window: .unavailable)
            store.dispatch(TabTrayAction.firefoxAccountChanged(context))
        default: break
        }
    }
}
