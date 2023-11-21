// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common

protocol TabTrayCoordinatorDelegate: AnyObject {
    func didDismissTabTray(from coordinator: TabTrayCoordinator)
}

protocol TabTrayNavigationHandler: AnyObject {
    func start(panelType: TabTrayPanelType, navigationController: UINavigationController)
}

class TabTrayCoordinator: BaseCoordinator, TabTrayViewControllerDelegate, TabTrayNavigationHandler {
    private var tabTrayViewController: TabTrayViewController!
    weak var parentCoordinator: TabTrayCoordinatorDelegate?

    init(router: Router) {
        super.init(router: router)
        initializeTabTrayViewController()
    }

    private func initializeTabTrayViewController() {
        tabTrayViewController = TabTrayViewController(delegate: self)
        router.setRootViewController(tabTrayViewController)
        tabTrayViewController.childPanelControllers = makeChildPanels()
        tabTrayViewController.navigationHandler = self
    }

    func start(with tabTraySection: TabTrayPanelType) {
        tabTrayViewController.setupOpenPanel(panelType: tabTraySection)
    }

    private func makeChildPanels() -> [UINavigationController] {
        let regularTabsPanel = TabDisplayPanel(isPrivateMode: false)
        let privateTabsPanel = TabDisplayPanel(isPrivateMode: true)
        let syncTabs = RemoteTabsPanel()
        return [
            ThemedNavigationController(rootViewController: regularTabsPanel),
            ThemedNavigationController(rootViewController: privateTabsPanel),
            ThemedNavigationController(rootViewController: syncTabs)
        ]
    }

    func start(panelType: TabTrayPanelType, navigationController: UINavigationController) {
        switch panelType {
        case .tabs:
            makeTabsCoordinator(navigationController: navigationController)
        case .privateTabs:
            makeTabsCoordinator(navigationController: navigationController)
        case .syncedTabs:
            makeSyncedTabsCoordinator(navigationController: navigationController)
        }
    }

    private func makeTabsCoordinator(navigationController: UINavigationController) {
        let router = DefaultRouter(navigationController: navigationController)
        let tabCoordinator = TabsCoordinator(parentCoordinator: parentCoordinator,
                                             router: router)
        add(child: tabCoordinator)
        (navigationController.topViewController as? TabDisplayPanel)?.navigationHandler = tabCoordinator
    }

    private func makeSyncedTabsCoordinator(navigationController: UINavigationController) {
        guard !childCoordinators.contains(where: { $0 is SyncedTabsCoordinator }) else { return }
        let router = DefaultRouter(navigationController: navigationController)
        let syncedCoordinator = SyncedTabsCoordinator(parentCoordinator: parentCoordinator,
                                                      router: router)
        add(child: syncedCoordinator)
        (navigationController.topViewController as? RemoteTabsPanel)?.navigationHandler = syncedCoordinator
    }

    // MARK: - TabTrayViewControllerDelegate
    func didFinish() {
        router.dismiss(animated: true, completion: nil)
        parentCoordinator?.didDismissTabTray(from: self)
    }
}
