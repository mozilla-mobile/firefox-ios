// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

protocol SyncedTabsNavigationHandler: AnyObject {
    func openInNewTab(_ url: URL, isPrivate: Bool)
}

class SyncedTabsCoordinator: BaseCoordinator, SyncedTabsNavigationHandler {
    // MARK: - Properties

    private weak var parentCoordinator: TabTrayCoordinatorDelegate?

    // MARK: - Initializers

    init(
        parentCoordinator: TabTrayCoordinatorDelegate?,
        router: Router
    ) {
        self.parentCoordinator = parentCoordinator
        super.init(router: router)
    }

    // MARK: - SyncedTabsNavigationHandler
    func openInNewTab(_ url: URL, isPrivate: Bool) {}
}
