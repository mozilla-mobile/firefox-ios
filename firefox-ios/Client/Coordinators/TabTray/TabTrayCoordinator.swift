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
    var tabTrayViewController: TabTrayViewController?
    private let profile: Profile
    private let tabManager: TabManager
    weak var parentCoordinator: TabTrayCoordinatorDelegate?

    init(router: Router,
         tabTraySection: TabTrayPanelType,
         profile: Profile,
         tabManager: TabManager) {
        self.profile = profile
        self.tabManager = tabManager
        super.init(router: router)
        initializeTabTrayViewController(panelType: tabTraySection)
    }

    func dismissChildTabTrayPanels() {
        // [FXIOS-10482] Initial bandaid for memory leaking during tab tray open/close. Needs further investigation.
        guard let childVCs = tabTrayViewController?.currentPanel?.viewControllers else { return }
        childVCs.forEach { ($0 as? TabDisplayPanelViewController)?.removeTabPanel() }
    }

    private func initializeTabTrayViewController(panelType: TabTrayPanelType) {
        let tabTrayViewController = TabTrayViewController(panelType: panelType, windowUUID: tabManager.windowUUID)
        router.setRootViewController(tabTrayViewController)
        tabTrayViewController.childPanelControllers = makeChildPanels()
        tabTrayViewController.delegate = self
        tabTrayViewController.navigationHandler = self

        self.tabTrayViewController = tabTrayViewController
    }

    func start(with tabTraySection: TabTrayPanelType) {
        tabTrayViewController?.setupOpenPanel(panelType: tabTraySection)
    }

    private func makeChildPanels() -> [UINavigationController] {
        let windowUUID = tabManager.windowUUID
        let regularTabsPanel = TabDisplayPanelViewController(isPrivateMode: false, windowUUID: windowUUID)
        let privateTabsPanel = TabDisplayPanelViewController(isPrivateMode: true, windowUUID: windowUUID)
        let syncTabs = RemoteTabsPanel(windowUUID: windowUUID)
        return [
            ThemedNavigationController(rootViewController: regularTabsPanel, windowUUID: windowUUID),
            ThemedNavigationController(rootViewController: privateTabsPanel, windowUUID: windowUUID),
            ThemedNavigationController(rootViewController: syncTabs, windowUUID: windowUUID)
        ]
    }

    func start(panelType: TabTrayPanelType, navigationController: UINavigationController) {
        TelemetryWrapper.recordEvent(category: .action,
                                     method: .open,
                                     object: .tabTray)
        switch panelType {
        case .tabs:
            makeTabsCoordinator(navigationController: navigationController)
        case .privateTabs:
            makeTabsCoordinator(navigationController: navigationController)
        case .syncedTabs:
            makeRemoteTabsCoordinator(navigationController: navigationController, for: tabManager.windowUUID)
        }
    }

    private func makeTabsCoordinator(navigationController: UINavigationController) {
        let router = DefaultRouter(navigationController: navigationController)
        let tabCoordinator = TabsCoordinator(router: router)
        add(child: tabCoordinator)
        tabCoordinator.parentCoordinator = self
    }

    private func makeRemoteTabsCoordinator(navigationController: UINavigationController, for window: WindowUUID) {
        guard !childCoordinators.contains(where: { $0 is RemoteTabsCoordinator }) else { return }
        let router = DefaultRouter(navigationController: navigationController)
        let remoteTabsCoordinator = RemoteTabsCoordinator(profile: profile,
                                                          router: router,
                                                          windowUUID: window)
        add(child: remoteTabsCoordinator)
        remoteTabsCoordinator.parentCoordinator = self
        (navigationController.topViewController as? RemoteTabsPanel)?.remoteTabsDelegate = remoteTabsCoordinator
    }

    // MARK: - ParentCoordinatorDelegate
    func didFinish(from childCoordinator: Coordinator) {
        TelemetryWrapper.recordEvent(category: .action,
                                     method: .close,
                                     object: .tabTray)
        remove(child: childCoordinator)
        parentCoordinator?.didDismissTabTray(from: self)
    }

    // MARK: - TabTrayViewControllerDelegate
    func didFinish() {
        TelemetryWrapper.recordEvent(category: .action,
                                     method: .close,
                                     object: .tabTray)
        parentCoordinator?.didDismissTabTray(from: self)
    }
}
