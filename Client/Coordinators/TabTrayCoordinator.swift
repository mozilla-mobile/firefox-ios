// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common

protocol TabTrayViewControllerDelegate: AnyObject {
    func didDismissTabTray()
}

class TabTrayCoordinator: BaseCoordinator, TabTrayViewControllerDelegate {
    private var tabTrayViewController: TabTrayViewController!
    weak var parentCoordinator: ParentCoordinatorDelegate?

    init(router: Router) {
        super.init(router: router)
        initializeTabTrayViewController()
    }

    private func initializeTabTrayViewController() {
        tabTrayViewController = TabTrayViewController(delegate: self)
        router.setRootViewController(tabTrayViewController)
    }

    func start() {}

    func didDismissTabTray() {
        router.dismiss(animated: true, completion: nil)
        parentCoordinator?.didFinish(from: self)
    }
}
