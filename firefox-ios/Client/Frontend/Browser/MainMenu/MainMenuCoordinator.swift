// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import MenuKit
import Shared

protocol MainMenuCoordinatorDelegate: AnyObject {
    func editLatestBookmark()
    func openURLInNewTab(_ url: URL?)
    func openNewTab(inPrivateMode: Bool)
    func showLibraryPanel(_ panel: Route.HomepanelSection)
    func showSettings(at destination: Route.SettingsSection)
    func showFindInPage()
    func showSignInView(fxaParameters: FxASignInViewParameters?)
    func updateZoomPageBarVisibility()
    func showShareSheet(with url: URL?)
}

class MainMenuCoordinator: BaseCoordinator, FeatureFlaggable {
    weak var parentCoordinator: ParentCoordinatorDelegate?
    weak var navigationHandler: MainMenuCoordinatorDelegate?

    let windowUUID: WindowUUID
    private let profile: Profile

    init(
        router: Router,
        windowUUID: WindowUUID,
        profile: Profile
    ) {
        self.windowUUID = windowUUID
        self.profile = profile
        super.init(router: router)
    }

    func start() {
        router.setRootViewController(
            createMainMenuViewController(),
            hideBar: true
        )
    }

    func showDetailViewController() {
        router.push(
            createMainMenuDetailViewController(),
            animated: true
        )
    }

    func dismissDetailViewController() {
        router.popViewController(animated: true)
    }

    func removeCoordinatorFromParent() {
        parentCoordinator?.didFinish(from: self)
    }

    func dismissMenuModal(animated: Bool) {
        router.dismiss(animated: animated, completion: nil)
        removeCoordinatorFromParent()
    }

    func navigateTo(_ destination: MenuNavigationDestination, animated: Bool) {
        router.dismiss(animated: animated, completion: { [weak self] in
            guard let self else { return }

            switch destination.destination {
            case .bookmarks:
                self.navigationHandler?.showLibraryPanel(.bookmarks)

            case .customizeHomepage:
                self.navigationHandler?.showSettings(at: .homePage)

            case .downloads:
                self.navigationHandler?.showLibraryPanel(.downloads)

            case .editBookmark:
                self.navigationHandler?.editLatestBookmark()

            case .findInPage:
                self.navigationHandler?.showFindInPage()

            case .goToURL:
                self.navigationHandler?.openURLInNewTab(destination.url)

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

            case .syncSignIn:
                let fxaParameters = FxASignInViewParameters(
                    launchParameters: FxALaunchParams(entrypoint: .browserMenu, query: [:]),
                    flowType: .emailLoginFlow,
                    referringPage: .appMenu
                )
                self.navigationHandler?.showSignInView(fxaParameters: fxaParameters)

            case .shareSheet:
                self.navigationHandler?.showShareSheet(with: destination.url)
                // self.navigationHandler?.showShareSheetForCurrentlySelectedTab()

            case .zoom:
                self.navigationHandler?.updateZoomPageBarVisibility()
            }

            removeCoordinatorFromParent()
        })
    }

    // MARK: - Private helpers

    private func createMainMenuViewController() -> MainMenuViewController {
        let mainMenuViewController = MainMenuViewController(windowUUID: windowUUID, profile: profile)
        mainMenuViewController.coordinator = self
        return mainMenuViewController
    }

    private func createMainMenuDetailViewController() -> MainMenuDetailsViewController {
        let detailVC = MainMenuDetailsViewController(windowUUID: windowUUID)
        detailVC.coordinator = self
        return detailVC
    }
}
