// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common

protocol TabTrayCoordinatorDelegate: AnyObject {
    func didDismissTabTray(from coordinator: TabTrayCoordinator)
}

class TabTrayCoordinator: BaseCoordinator {
    private var tabTrayViewController: TabTrayViewController!
    weak var parentCoordinator: LibraryCoordinatorDelegate?

    init(router: Router) {
        super.init(router: router)
        initializeTabTrayViewController()
    }

    private func initializeTabTrayViewController() {
        tabTrayViewController = TabTrayViewController()
        router.setRootViewController(tabTrayViewController)
    }

    func start() {}
}
