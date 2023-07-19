// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Shared
import Storage

protocol LibraryCoordinatorDelegate: AnyObject, LibraryPanelDelegate {
    func didFinishLibrary(from coordinator: LibraryCoordinator)
}

protocol LibraryNavigationHandler: AnyObject {
    func start(panelType: LibraryPanelType, navigationController: UINavigationController)
}

class LibraryCoordinator: BaseCoordinator, LibraryPanelDelegate, LibraryNavigationHandler {
    private let profile: Profile
    private let tabManager: TabManager
    private let libraryViewController: LibraryViewController
    weak var parentCoordinator: LibraryCoordinatorDelegate?

    init(
        router: Router,
        profile: Profile = AppContainer.shared.resolve(),
        tabManager: TabManager = AppContainer.shared.resolve()
    ) {
        self.libraryViewController = LibraryViewController(profile: profile, tabManager: tabManager)
        self.profile = profile
        self.tabManager = tabManager
        super.init(router: router)
        self.router.setRootViewController(libraryViewController)
    }

    func start(with homepanelSection: Route.HomepanelSection) {
        libraryViewController.setupOpenPanel(panelType: homepanelSection.libraryPanel)
        libraryViewController.delegate = self
        libraryViewController.navigationHandler = self
        libraryViewController.resetHistoryPanelPagination()
    }

    // MARK: - LibraryNavigationHandler

    func start(panelType: LibraryPanelType, navigationController: UINavigationController) {
        switch panelType {
        case .bookmarks:
            makeBookmarksCoordinator(navigationController: navigationController)
        case .history:
            // HistoryCoordinator will be implemented with FXIOS-6978
            break
        case .downloads:
            // DownloadsCoordinator will be implemented with FXIOS-6978
            break
        case .readingList:
            // ReadingListCoordinator will be implemented with FXIOS-6978
            break
        }
    }

    private func makeBookmarksCoordinator(navigationController: UINavigationController) {
        guard !childCoordinators.contains(where: { $0 is BookmarksCoordinator }) else { return }
        let router = DefaultRouter(navigationController: navigationController)
        let bookmarksCoordinator = BookmarksCoordinator(
            router: router,
            profile: profile,
            parentCoordinator: parentCoordinator
        )
        add(child: bookmarksCoordinator)
        (navigationController.topViewController as? BookmarksPanel)?.bookmarkCoordinatorDelegate = bookmarksCoordinator
    }

    // MARK: - LibraryPanelDelegate

    func libraryPanelDidRequestToOpenInNewTab(_ url: URL, isPrivate: Bool) {
        parentCoordinator?.libraryPanelDidRequestToOpenInNewTab(url, isPrivate: isPrivate)
    }

    func libraryPanel(didSelectURL url: URL, visitType: Storage.VisitType) {
        parentCoordinator?.libraryPanel(didSelectURL: url, visitType: visitType)
    }

    func didFinish() {
        parentCoordinator?.didFinishLibrary(from: self)
    }
}
