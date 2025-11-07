// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common
import Shared

protocol HistoryCoordinatorDelegate: AnyObject, LibraryPanelCoordinatorDelegate {
    @MainActor
    func showRecentlyClosedTab()
}

class HistoryCoordinator: BaseCoordinator,
                          HistoryCoordinatorDelegate,
                          Notifiable {
    // MARK: - Properties

    private let profile: Profile
    private let windowUUID: WindowUUID
    private let notificationCenter: NotificationProtocol
    private weak var parentCoordinator: LibraryCoordinatorDelegate?
    private weak var navigationHandler: LibraryNavigationHandler?

    // MARK: - Initializers

    init(
        profile: Profile,
        windowUUID: WindowUUID,
        router: Router,
        notificationCenter: NotificationProtocol = NotificationCenter.default,
        parentCoordinator: LibraryCoordinatorDelegate?,
        navigationHandler: LibraryNavigationHandler?
    ) {
        self.profile = profile
        self.windowUUID = windowUUID
        self.parentCoordinator = parentCoordinator
        self.notificationCenter = notificationCenter
        self.navigationHandler = navigationHandler
        super.init(router: router)

        startObservingNotifications(
            withNotificationCenter: notificationCenter,
            forObserver: self,
            observing: [.OpenClearRecentHistory]
        )
    }

    // MARK: Notifiable
    func handleNotifications(_ notification: Notification) {
        guard notification.name == .OpenClearRecentHistory else { return }

        ensureMainThread {
            guard let historyPanel = self.router.rootViewController as? HistoryPanel else { return }
            historyPanel.showClearRecentHistory()
        }
    }

    // MARK: - HistoryCoordinatorDelegate

    func showRecentlyClosedTab() {
        let controller = RecentlyClosedTabsPanel(profile: profile, windowUUID: windowUUID)
        controller.title = .RecentlyClosedTabsPanelTitle
        controller.libraryPanelDelegate = parentCoordinator
        controller.recentlyClosedTabsDelegate = parentCoordinator
        router.push(controller)
    }

    func shareLibraryItem(url: URL, sourceView: UIView) {
        navigationHandler?.shareLibraryItem(url: url, sourceView: sourceView)
    }
}
