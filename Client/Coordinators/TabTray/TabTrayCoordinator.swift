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

class TabTrayCoordinator: BaseCoordinator,
                          ParentCoordinatorDelegate,
                          TabTrayViewControllerDelegate,
                          TabTrayNavigationHandler {
    private var tabTrayViewController: TabTrayViewController!
    private var profile: Profile
    weak var parentCoordinator: TabTrayCoordinatorDelegate?

    init(router: Router,
         tabTraySection: TabTrayPanelType,
         profile: Profile) {
        self.profile = profile
        super.init(router: router)
        initializeTabTrayViewController(selectedTab: tabTraySection)
    }

    private func initializeTabTrayViewController(selectedTab: TabTrayPanelType) {
        tabTrayViewController = TabTrayViewController(selectedTab: selectedTab)
        router.setRootViewController(tabTrayViewController)
        tabTrayViewController.childPanelControllers = makeChildPanels()
        tabTrayViewController.delegate = self
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
            makeRemoteTabsCoordinator(navigationController: navigationController)
        }
    }

    private func makeTabsCoordinator(navigationController: UINavigationController) {
        let router = DefaultRouter(navigationController: navigationController)
        let tabCoordinator = TabsCoordinator(router: router)
        add(child: tabCoordinator)
        tabCoordinator.parentCoordinator = self
    }

    private func makeRemoteTabsCoordinator(navigationController: UINavigationController) {
        guard !childCoordinators.contains(where: { $0 is RemoteTabsCoordinator }) else { return }
        let router = DefaultRouter(navigationController: navigationController)
        let remoteTabsCoordinator = RemoteTabsCoordinator(profile: profile,
                                                          router: router)
        add(child: remoteTabsCoordinator)
        remoteTabsCoordinator.parentCoordinator = self
        (navigationController.topViewController as? RemoteTabsPanel)?.remoteTabsDelegate = remoteTabsCoordinator
    }

    // MARK: - ParentCoordinatorDelegate
    func didFinish(from childCoordinator: Coordinator) {
        remove(child: childCoordinator)
        parentCoordinator?.didDismissTabTray(from: self)
    }

    // MARK: - TabTrayViewControllerDelegate
    func didFinish() {
        parentCoordinator?.didDismissTabTray(from: self)
    }
}
