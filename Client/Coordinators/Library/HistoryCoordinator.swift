// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

protocol HistoryCoordinatorDelegate: AnyObject {
    func showRecentlyClosedTab()
}

class HistoryCoordinator: BaseCoordinator, HistoryCoordinatorDelegate {
    // MARK: - Properties

    private let profile: Profile
    private weak var parentCoordinator: LibraryCoordinatorDelegate?

    // MARK: - Initializers

    init(
        profile: Profile,
        router: Router,
        parentCoordinator: LibraryCoordinatorDelegate?
    ) {
        self.profile = profile
        self.parentCoordinator = parentCoordinator
        super.init(router: router)
    }

    // MARK: - HistoryCoordinatorDelegate

    func showRecentlyClosedTab() {
        let controller = RecentlyClosedTabsPanel(profile: profile)
        controller.libraryPanelDelegate = parentCoordinator
        router.push(controller)
    }
}
