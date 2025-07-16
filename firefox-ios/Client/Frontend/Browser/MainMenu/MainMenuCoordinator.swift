// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation

protocol MainMenuCoordinatorDelegate: AnyObject {
    @MainActor
    func editBookmarkForCurrentTab()

    @MainActor
    func openURLInNewTab(_ url: URL?)

    @MainActor
    func openNewTab(inPrivateMode: Bool)

    @MainActor
    func showLibraryPanel(_ panel: Route.HomepanelSection)

    @MainActor
    func showSettings(at destination: Route.SettingsSection)

    @MainActor
    func showFindInPage()

    @MainActor
    func showSignInView(fxaParameters: FxASignInViewParameters?)

    @MainActor
    func updateZoomPageBarVisibility()

    @MainActor
    func presentSavePDFController()

    @MainActor
    func presentSiteProtections()

    @MainActor
    func showPrintSheet()

    /// Open the share sheet to share the currently selected `Tab`.
    @MainActor
    func showShareSheetForCurrentlySelectedTab()
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

    func startWithNavController() {
        let mainMenuViewController = createMainMenuViewController()

        let mainMenuNavController = UINavigationController(rootViewController: mainMenuViewController)
        mainMenuNavController.isNavigationBarHidden = true

        if let sheetPresentationController = mainMenuNavController.sheetPresentationController {
            sheetPresentationController.detents = [.medium(), .large()]
        }
        mainMenuNavController.sheetPresentationController?.prefersEdgeAttachedInCompactHeight = true
        mainMenuNavController.sheetPresentationController?.prefersGrabberVisible = true
        router.present(mainMenuNavController, animated: true, completion: nil)
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

            self.handleDestination(destination)

            removeCoordinatorFromParent()
        })
    }

    private func handleDestination(_ destination: MenuNavigationDestination) {
        switch destination.destination {
        case .bookmarks:
            navigationHandler?.showLibraryPanel(.bookmarks)

        case .customizeHomepage:
            navigationHandler?.showSettings(at: .homePage)

        case .downloads:
            navigationHandler?.showLibraryPanel(.downloads)

        case .editBookmark:
            navigationHandler?.editBookmarkForCurrentTab()

        case .findInPage:
            navigationHandler?.showFindInPage()

        case .goToURL:
            navigationHandler?.openURLInNewTab(destination.url)

        case .history:
            navigationHandler?.showLibraryPanel(.history)

        case .newTab:
            navigationHandler?.openNewTab(inPrivateMode: false)

        case .newPrivateTab:
            navigationHandler?.openNewTab(inPrivateMode: true)

        case .passwords:
            navigationHandler?.showSettings(at: .password)

        case .settings:
            navigationHandler?.showSettings(at: .general)

        case .syncSignIn:
            let fxaParameters = FxASignInViewParameters(
                launchParameters: FxALaunchParams(entrypoint: .browserMenu, query: [:]),
                flowType: .emailLoginFlow,
                referringPage: .appMenu
            )
            navigationHandler?.showSignInView(fxaParameters: fxaParameters)

        case .printSheet, .printSheetV2:
            navigationHandler?.showPrintSheet()

        case .shareSheet:
            navigationHandler?.showShareSheetForCurrentlySelectedTab()

        case .saveAsPDF, .saveAsPDFV2:
            navigationHandler?.presentSavePDFController()

        case .zoom:
            navigationHandler?.updateZoomPageBarVisibility()

        case .siteProtections:
            self.navigationHandler?.presentSiteProtections()

        case .defaultBrowser:
            DefaultApplicationHelper().openSettings()
        }
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
