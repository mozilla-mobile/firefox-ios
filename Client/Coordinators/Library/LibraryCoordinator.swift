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
        libraryViewController.childPanelControllers = makeChildPanels()
        libraryViewController.delegate = self
        libraryViewController.navigationHandler = self
        libraryViewController.setupOpenPanel(panelType: homepanelSection.libraryPanel)
        libraryViewController.resetHistoryPanelPagination()
    }

    private func makeChildPanels() -> [UINavigationController] {
        let bookmarksPanel = BookmarksPanel(viewModel: BookmarksPanelViewModel(profile: profile))
        let historyPanel = HistoryPanel(profile: profile, tabManager: tabManager)
        let downloadsPanel = DownloadsPanel()
        let readingListPanel = ReadingListPanel(profile: profile)
        return [
            ThemedNavigationController(rootViewController: bookmarksPanel),
            ThemedNavigationController(rootViewController: historyPanel),
            ThemedNavigationController(rootViewController: downloadsPanel),
            ThemedNavigationController(rootViewController: readingListPanel)
        ]
    }

    // MARK: - LibraryNavigationHandler

    func start(panelType: LibraryPanelType, navigationController: UINavigationController) {
        switch panelType {
        case .bookmarks:
            makeBookmarksCoordinator(navigationController: navigationController)
        case .history:
            makeHistoryCoordinator(navigationController: navigationController)
        case .downloads:
            makeDownloadsCoordinator(navigationController: navigationController)
        case .readingList:
            makeReadingListCoordinator(navigationController: navigationController)
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

    private func makeHistoryCoordinator(navigationController: UINavigationController) {
        guard !childCoordinators.contains(where: { $0 is HistoryCoordinator }) else { return }
        let router = DefaultRouter(navigationController: navigationController)
        let historyCoordinator = HistoryCoordinator(
            profile: profile,
            router: router,
            parentCoordinator: parentCoordinator
        )
        add(child: historyCoordinator)
        (navigationController.topViewController as? HistoryPanel)?.historyCoordinatorDelegate = historyCoordinator
    }

    private func makeDownloadsCoordinator(navigationController: UINavigationController) {
        guard !childCoordinators.contains(where: { $0 is DownloadsCoordinator }) else { return }
        let router = DefaultRouter(navigationController: navigationController)
        let downloadsCoordinator = DownloadsCoordinator(
            router: router,
            profile: profile,
            parentCoordinator: parentCoordinator
        )
        add(child: downloadsCoordinator)
        (navigationController.topViewController as? DownloadsPanel)?.navigationHandler = downloadsCoordinator
    }

    private func makeReadingListCoordinator(navigationController: UINavigationController) {
        guard !childCoordinators.contains(where: { $0 is ReadingListCoordinator }) else { return }
        let router = DefaultRouter(navigationController: navigationController)
        let readingListCoordinator = ReadingListCoordinator(
            parentCoordinator: parentCoordinator,
            router: router
        )
        add(child: readingListCoordinator)
        (navigationController.topViewController as? ReadingListPanel)?.navigationHandler = readingListCoordinator
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
