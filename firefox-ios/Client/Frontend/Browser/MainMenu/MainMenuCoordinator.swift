// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import MenuKit
import Shared

protocol MainMenuCoordinatorDelegate: AnyObject {
    func openURLInNewTab(_ url: URL?)
    func openNewTab(inPrivateMode: Bool)
    func showLibraryPanel(_ panel: Route.HomepanelSection)
    func showSettings(at destination: Route.SettingsSection)
    func showFindInPage()
}

class MainMenuCoordinator: BaseCoordinator, FeatureFlaggable {
    weak var parentCoordinator: ParentCoordinatorDelegate?
    weak var navigationHandler: MainMenuCoordinatorDelegate?

    private let windowUUID: WindowUUID
    private var navController: UINavigationController!

    init(router: Router, windowUUID: WindowUUID) {
        self.windowUUID = windowUUID
        super.init(router: router)
    }

    func showMenuModal() {
        let viewController = createMainMenuViewController()
        navController = UINavigationController(rootViewController: viewController)
        navController.modalPresentationStyle = .pageSheet
        navController.isNavigationBarHidden = true

        if let sheet = navController.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
        }

        router.present(navController, animated: true)
    }

    func showDetailViewController(with submenu: [MenuSection]) {
        navController.pushViewController(
            createMainMenuDetailViewController(with: submenu),
            animated: true
        )
    }

    func dismissDetailViewController() {
        navController.popViewController(animated: true)
    }

    func dismissMenuModal(animated: Bool) {
        router.dismiss(animated: animated, completion: nil)
        self.parentCoordinator?.didFinish(from: self)
    }

    func navigateTo(_ destination: MainMenuNavigationDestination, animated: Bool) {
        router.dismiss(animated: animated, completion: { [weak self] in
            guard let self else { return }

            switch destination {
            case .bookmarks:
                self.navigationHandler?.showLibraryPanel(.bookmarks)
            case .customizeHomepage:
                self.navigationHandler?.showSettings(at: .homePage)
            case .downloads:
                self.navigationHandler?.showLibraryPanel(.downloads)
            case .findInPage:
                self.navigationHandler?.showFindInPage()
            case .goToURL(let url):
                self.navigationHandler?.openURLInNewTab(url)
            case .history:
                self.navigationHandler?.showLibraryPanel(.history)
            case .newTab:
                self.navigationHandler?.openNewTab(inPrivateMode: false)
            case .newPrivateTab:
                self.navigationHandler?.openNewTab(inPrivateMode: true)
            case .passwords:
                self.navigationHandler?.showSettings(at: .password)
            case .settings:
                self.navigationHandler?.showSettings(at: .general)
            }

            self.parentCoordinator?.didFinish(from: self)
        })
    }

    // MARK: - Private helpers
    private func createMainMenuViewController() -> MainMenuViewController {
        let mainMenuViewController = MainMenuViewController(windowUUID: windowUUID)
        mainMenuViewController.coordinator = self
        return mainMenuViewController
    }

    private func createMainMenuDetailViewController(with submenu: [MenuSection]) -> MainMenuDetailViewController {
        let detailVC = MainMenuDetailViewController(
            windowUUID: windowUUID,
            with: submenu
        )
        detailVC.coordinator = self
        return detailVC
    }
}
