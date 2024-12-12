// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Shared
import Storage

import enum MozillaAppServices.VisitType

protocol LibraryCoordinatorDelegate: AnyObject, LibraryPanelDelegate, RecentlyClosedPanelDelegate {
    func didFinishLibrary(from coordinator: LibraryCoordinator)
}

protocol LibraryNavigationHandler: AnyObject {
    func start(panelType: LibraryPanelType, navigationController: UINavigationController)
    func shareLibraryItem(url: URL, sourceView: UIView)
    func setNavigationBarHidden(_ value: Bool)
}

class LibraryCoordinator: BaseCoordinator,
                          LibraryPanelDelegate,
                          LibraryNavigationHandler,
                          ParentCoordinatorDelegate,
                          BookmarksRefactorFeatureFlagProvider {
    private let profile: Profile
    private let tabManager: TabManager
    private var libraryViewController: LibraryViewController!
    weak var parentCoordinator: LibraryCoordinatorDelegate?
    override var isDismissable: Bool { false }
    private var windowUUID: WindowUUID { return tabManager.windowUUID }

    init(
        router: Router,
        profile: Profile = AppContainer.shared.resolve(),
        tabManager: TabManager
    ) {
        self.profile = profile
        self.tabManager = tabManager
        super.init(router: router)
        initializeLibraryViewController()
    }

    private func initializeLibraryViewController() {
        libraryViewController = LibraryViewController(profile: profile, tabManager: tabManager)
        router.setRootViewController(libraryViewController)
        libraryViewController.childPanelControllers = makeChildPanels()
        libraryViewController.delegate = self
        libraryViewController.navigationHandler = self
    }

    func start(with homepanelSection: Route.HomepanelSection) {
        libraryViewController.setupOpenPanel(panelType: homepanelSection.libraryPanel)
    }

    private func makeChildPanels() -> [UINavigationController] {
        let bookmarksPanel: UIViewController
        if isBookmarkRefactorEnabled {
            bookmarksPanel = BookmarksViewController(viewModel: BookmarksPanelViewModel(profile: profile,
                                                                                        bookmarksHandler: profile.places),
                                                     windowUUID: windowUUID)
        } else {
            bookmarksPanel = LegacyBookmarksPanel(viewModel: BookmarksPanelViewModel(profile: profile,
                                                                                     bookmarksHandler: profile.places),
                                                  windowUUID: windowUUID)
        }
        let historyPanel = HistoryPanel(profile: profile, windowUUID: windowUUID)
        let downloadsPanel = DownloadsPanel(windowUUID: windowUUID)
        let readingListPanel = ReadingListPanel(profile: profile, windowUUID: windowUUID)
        return [
            ThemedNavigationController(rootViewController: bookmarksPanel, windowUUID: windowUUID),
            ThemedNavigationController(rootViewController: historyPanel, windowUUID: windowUUID),
            ThemedNavigationController(rootViewController: downloadsPanel, windowUUID: windowUUID),
            ThemedNavigationController(rootViewController: readingListPanel, windowUUID: windowUUID)
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

    func shareLibraryItem(url: URL, sourceView: UIView) {
        if let coordinator = childCoordinators.first(where: { $0 is ShareSheetCoordinator }) as? ShareSheetCoordinator {
            // The share sheet extension coordinator wasn't correctly removed in the last share session. Attempt to recover.
            logger.log(
                "ShareSheetCoordinator already exists when it shouldn't. Removing and recreating it to access share sheet",
                level: .info,
                category: .shareSheet,
                extra: ["existing ShareSheetCoordinator UUID": "\(coordinator.windowUUID)",
                        "LibraryCoordinator windowUUID": "\(windowUUID)"]
            )

            coordinator.dismiss()
        }

        let coordinator = ShareSheetCoordinator(
            alertContainer: UIView(),
            router: router,
            profile: profile,
            parentCoordinator: self,
            tabManager: tabManager
        )
        add(child: coordinator)

        // Note: Called from History, Bookmarks, and Reading List long presses > Share from the context menu
        coordinator.start(shareType: .site(url: url), shareMessage: nil, sourceView: sourceView)
    }

    private func makeBookmarksCoordinator(navigationController: UINavigationController) {
        guard !childCoordinators.contains(where: { $0 is BookmarksCoordinator }) else { return }
        let router = DefaultRouter(navigationController: navigationController)
        let bookmarksCoordinator = BookmarksCoordinator(
            router: router,
            profile: profile,
            windowUUID: windowUUID,
            parentCoordinator: parentCoordinator,
            navigationHandler: self
        )
        add(child: bookmarksCoordinator)
        if isBookmarkRefactorEnabled {
            (navigationController.topViewController as? BookmarksViewController)?
                .bookmarkCoordinatorDelegate = bookmarksCoordinator
        } else {
            (navigationController.topViewController as? LegacyBookmarksPanel)?
                .bookmarkCoordinatorDelegate = bookmarksCoordinator
        }
    }

    private func makeHistoryCoordinator(navigationController: UINavigationController) {
        guard !childCoordinators.contains(where: { $0 is HistoryCoordinator }) else { return }
        let router = DefaultRouter(navigationController: navigationController)
        let historyCoordinator = HistoryCoordinator(
            profile: profile,
            windowUUID: windowUUID,
            router: router,
            parentCoordinator: parentCoordinator,
            navigationHandler: self
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
            parentCoordinator: parentCoordinator,
            tabManager: tabManager
        )
        add(child: downloadsCoordinator)
        (navigationController.topViewController as? DownloadsPanel)?.navigationHandler = downloadsCoordinator
    }

    private func makeReadingListCoordinator(navigationController: UINavigationController) {
        guard !childCoordinators.contains(where: { $0 is ReadingListCoordinator }) else { return }
        let router = DefaultRouter(navigationController: navigationController)
        let readingListCoordinator = ReadingListCoordinator(
            parentCoordinator: parentCoordinator,
            navigationHandler: self,
            router: router
        )
        add(child: readingListCoordinator)
        (navigationController.topViewController as? ReadingListPanel)?.navigationHandler = readingListCoordinator
    }

    func setNavigationBarHidden(_ value: Bool) {
        libraryViewController.setNavigationBarHidden(value)
    }

    // MARK: - ParentCoordinatorDelegate

    func didFinish(from childCoordinator: any Coordinator) {
        remove(child: childCoordinator)
    }

    // MARK: - LibraryPanelDelegate

    func libraryPanelDidRequestToOpenInNewTab(_ url: URL, isPrivate: Bool) {
        parentCoordinator?.libraryPanelDidRequestToOpenInNewTab(url, isPrivate: isPrivate)
    }

    func libraryPanel(didSelectURL url: URL, visitType: VisitType) {
        parentCoordinator?.libraryPanel(didSelectURL: url, visitType: visitType)
    }

    func didFinish() {
        parentCoordinator?.didFinishLibrary(from: self)
    }

    var libraryPanelWindowUUID: WindowUUID {
        return windowUUID
    }
}
