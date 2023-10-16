// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common
import Shared
import Storage

protocol HistoryCoordinatorDelegate: AnyObject {
    func showRecentlyClosedTab()

    /// Shows table view controller with searched sites grouped.
    func showSearchGroupedItems(_ items: ASGroup<Site>)
}

class HistoryCoordinator: BaseCoordinator, HistoryCoordinatorDelegate {
    // MARK: - Properties

    private let profile: Profile
    private let notificationCenter: NotificationProtocol
    private weak var parentCoordinator: LibraryCoordinatorDelegate?

    // MARK: - Initializers

    init(
        profile: Profile,
        router: Router,
        notificationCenter: NotificationProtocol = NotificationCenter.default,
        parentCoordinator: LibraryCoordinatorDelegate?
    ) {
        self.profile = profile
        self.parentCoordinator = parentCoordinator
        self.notificationCenter = notificationCenter
        super.init(router: router)
        self.notificationCenter.addObserver(self, selector: #selector(openClearHistory), name: .OpenClearRecentHistory, object: nil)
    }

    @objc
    private func openClearHistory() {
        guard let historyPanel = router.rootViewController as? HistoryPanel else { return }
        historyPanel.showClearRecentHistory()
    }

    // MARK: - HistoryCoordinatorDelegate

    func showRecentlyClosedTab() {
        let controller = RecentlyClosedTabsPanel(profile: profile)
        controller.title = .RecentlyClosedTabsPanelTitle
        controller.libraryPanelDelegate = parentCoordinator
        controller.recentlyClosedTabsDelegate = parentCoordinator
        router.push(controller)
    }

    func showSearchGroupedItems(_ items: ASGroup<Site>) {
        let asGroupListViewModel = SearchGroupedItemsViewModel(asGroup: items, presenter: .historyPanel)
        let asGroupListVC = SearchGroupedItemsViewController(viewModel: asGroupListViewModel, profile: profile)
        asGroupListVC.libraryPanelDelegate = parentCoordinator
        asGroupListVC.title = items.displayTitle
        router.push(asGroupListVC)
    }

    deinit {
        notificationCenter.removeObserver(self)
    }
}
