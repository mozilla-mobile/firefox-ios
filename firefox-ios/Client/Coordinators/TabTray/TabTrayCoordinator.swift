// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Storage

protocol TabTrayCoordinatorDelegate: AnyObject {
    func didDismissTabTray(from coordinator: TabTrayCoordinator)
}

protocol TabTrayNavigationHandler: AnyObject {
    func start(panelType: TabTrayPanelType, navigationController: UINavigationController)
    func shareTab(url: URL, sourceView: UIView)
}

class TabTrayCoordinator: BaseCoordinator,
                          ParentCoordinatorDelegate,
                          TabTrayViewControllerDelegate,
                          TabTrayNavigationHandler {
    private var tabTrayViewController: TabTrayViewController!
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
        initializeTabTrayViewController(selectedTab: tabTraySection)
    }

    func dismissChildTabTrayPanels() {
        // [FXIOS-10482] Initial fix for memory leak. Needs further investigation.
        guard let childVCs = tabTrayViewController.currentPanel?.viewControllers else { return }
        childVCs.forEach { ($0 as? TabDisplayPanel)?.removeTabPanel() }
    }

    private func initializeTabTrayViewController(selectedTab: TabTrayPanelType) {
        tabTrayViewController = TabTrayViewController(selectedTab: selectedTab, windowUUID: tabManager.windowUUID)
        router.setRootViewController(tabTrayViewController)
        tabTrayViewController.childPanelControllers = makeChildPanels()
        tabTrayViewController.delegate = self
        tabTrayViewController.navigationHandler = self
    }

    func start(with tabTraySection: TabTrayPanelType) {
        tabTrayViewController.setupOpenPanel(panelType: tabTraySection)
    }

    private func makeChildPanels() -> [UINavigationController] {
        let windowUUID = tabManager.windowUUID
        let regularTabsPanel = TabDisplayPanel(isPrivateMode: false, windowUUID: windowUUID)
        let privateTabsPanel = TabDisplayPanel(isPrivateMode: true, windowUUID: windowUUID)
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

    func shareTab(url: URL, sourceView: UIView) {
        guard !childCoordinators.contains(where: { $0 is ShareExtensionCoordinator }) else { return }
        let coordinator = makeShareExtensionCoordinator()
        coordinator.start(url: url, sourceView: sourceView)
    }

    private func makeShareExtensionCoordinator() -> ShareExtensionCoordinator {
        let coordinator = ShareExtensionCoordinator(
            alertContainer: UIView(),
            router: router,
            profile: profile,
            parentCoordinator: self,
            tabManager: tabManager
        )
        add(child: coordinator)
        return coordinator
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
