// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common

protocol TabTrayViewControllerDelegate: AnyObject {
    func didDismissTabTray()
}

protocol TabTrayNavigationHandler: AnyObject {
    func start(panelType: TabTrayPanelType, navigationController: UINavigationController)
}

class TabTrayCoordinator: BaseCoordinator, TabTrayViewControllerDelegate, TabTrayNavigationHandler {
    private var tabTrayViewController: TabTrayViewController!
    weak var parentCoordinator: ParentCoordinatorDelegate?

    init(router: Router) {
        super.init(router: router)
        initializeTabTrayViewController()
    }

    private func initializeTabTrayViewController() {
        tabTrayViewController = TabTrayViewController(delegate: self)
        router.setRootViewController(tabTrayViewController)
        tabTrayViewController.childPanelControllers = makeChildPanels()
        tabTrayViewController.delegate = self
        tabTrayViewController.navigationHandler = self
    }

    func start(with tabTraySection: TabTrayPanelType) {
        tabTrayViewController.setupOpenPanel(panelType: tabTraySection)
    }

    private func makeChildPanels() -> [UINavigationController] {
        let regularTabsPanel = TabDisplayViewController(isPrivateMode: false)
        let privateTabsPanel = TabDisplayViewController(isPrivateMode: true)
        let syncTabs = RemoteTabsPanel()
        return [
            ThemedNavigationController(rootViewController: regularTabsPanel),
            ThemedNavigationController(rootViewController: privateTabsPanel),
            ThemedNavigationController(rootViewController: syncTabs)
        ]
    }

    func start(panelType: TabTrayPanelType, navigationController: UINavigationController) {
        tabTrayViewController.setupOpenPanel(panelType: panelType)
    }

    func didDismissTabTray() {
        router.dismiss(animated: true, completion: nil)
        parentCoordinator?.didFinish(from: self)
    }
}
