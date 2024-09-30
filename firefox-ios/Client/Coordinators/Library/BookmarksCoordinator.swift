// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Storage
import Common
import MozillaAppServices

protocol BookmarksCoordinatorDelegate: AnyObject, LibraryPanelCoordinatorDelegate {
    func start(from folder: FxBookmarkNode)

    /// Shows the bookmark detail to modify a bookmark folder
    func showBookmarkDetail(for node: FxBookmarkNode, folder: FxBookmarkNode, completion: (() -> Void)?)

    /// Shows the bookmark detail to create a new bookmark or folder in the parent folder
    func showBookmarkDetail(
        bookmarkType: BookmarkNodeType,
        parentBookmarkFolder: FxBookmarkNode,
        updatePanelState: ((LibraryPanelSubState) -> Void)?
    )
}

extension BookmarksCoordinatorDelegate {
    func showBookmarkDetail(
        bookmarkType: BookmarkNodeType,
        parentBookmarkFolder: FxBookmarkNode,
        updatePanelState: ((LibraryPanelSubState) -> Void)? = nil
    ) {
        showBookmarkDetail(
            bookmarkType: bookmarkType,
            parentBookmarkFolder: parentBookmarkFolder,
            updatePanelState: updatePanelState
        )
    }
}

class BookmarksCoordinator: BaseCoordinator,
                            BookmarksCoordinatorDelegate,
                            BookmarksRefactorFeatureFlagProvider {
    // MARK: - Properties

    private let profile: Profile
    private weak var parentCoordinator: LibraryCoordinatorDelegate?
    private weak var navigationHandler: LibraryNavigationHandler?
    private let windowUUID: WindowUUID

    // MARK: - Initializers

    init(
        router: Router,
        profile: Profile,
        windowUUID: WindowUUID,
        parentCoordinator: LibraryCoordinatorDelegate?,
        navigationHandler: LibraryNavigationHandler?
    ) {
        self.profile = profile
        self.windowUUID = windowUUID
        self.parentCoordinator = parentCoordinator
        self.navigationHandler = navigationHandler
        super.init(router: router)
    }

    // MARK: - BookmarksCoordinatorDelegate

    func start(from folder: FxBookmarkNode) {
        let viewModel = BookmarksPanelViewModel(profile: profile,
                                                bookmarksHandler: profile.places,
                                                bookmarkFolderGUID: folder.guid)
        if isBookmarkRefactorEnabled {
            let controller = BookmarksViewController(viewModel: viewModel, windowUUID: windowUUID)
            controller.bookmarkCoordinatorDelegate = self
            controller.libraryPanelDelegate = parentCoordinator
            router.push(controller)
        } else {
            let controller = LegacyBookmarksPanel(viewModel: viewModel, windowUUID: windowUUID)
            controller.bookmarkCoordinatorDelegate = self
            controller.libraryPanelDelegate = parentCoordinator
            router.push(controller)
        }
    }

    func showBookmarkDetail(for node: FxBookmarkNode, folder: FxBookmarkNode, completion: (() -> Void)? = nil) {
        TelemetryWrapper.recordEvent(category: .action, method: .change, object: .bookmark, value: .bookmarksPanel)
        if isBookmarkRefactorEnabled {
            router.push(makeDetailController(for: node, folder: folder))
        } else {
            let detailController = LegacyBookmarkDetailPanel(profile: profile,
                                                             windowUUID: windowUUID,
                                                             bookmarkNode: node,
                                                             parentBookmarkFolder: folder)
            router.push(detailController)
        }
    }

    func showBookmarkDetail(
        bookmarkType: BookmarkNodeType,
        parentBookmarkFolder: FxBookmarkNode,
        updatePanelState: ((LibraryPanelSubState) -> Void)? = nil
    ) {
        if isBookmarkRefactorEnabled {
            let detailController = makeDetailController(for: bookmarkType, parentFolder: parentBookmarkFolder)
            router.push(detailController)
        } else {
            let detailController = LegacyBookmarkDetailPanel(
                profile: profile,
                windowUUID: windowUUID,
                withNewBookmarkNodeType: bookmarkType,
                parentBookmarkFolder: parentBookmarkFolder
            ) {
                updatePanelState?($0)
            }
            router.push(detailController)
        }
    }

    func shareLibraryItem(url: URL, sourceView: UIView) {
        navigationHandler?.shareLibraryItem(url: url, sourceView: sourceView)
    }

    // MARK: - Factory

    private func makeDetailController(for type: BookmarkNodeType, parentFolder: FxBookmarkNode) -> UIViewController {
        if type == .folder {
            return makeEditFolderController(for: nil, folder: parentFolder)
        }
        if type == .bookmark {
            return makeEditBookmarkController(for: nil, folder: parentFolder)
        }
        return UIViewController()
    }

    private func makeDetailController(for node: FxBookmarkNode, folder: FxBookmarkNode) -> UIViewController {
        if let node = node as? BookmarkItemData {
            return makeEditBookmarkController(for: node, folder: folder)
        }
        if let node = node as? BookmarkFolderData {
            return makeEditFolderController(for: node, folder: folder)
        }
        return UIViewController()
    }

    // TODO: understand FXBookmarkNode dependency other than BookmarkItemData
    private func makeEditBookmarkController(for node: BookmarkItemData?, folder: FxBookmarkNode) -> UIViewController {
        let viewModel = EditBookmarkViewModel(parentFolder: folder, node: node, profile: profile)
        viewModel.onBookmarkSaved = { [weak self] in
            self?.reloadLastBookmarksController()
        }
        let controller = EditBookmarkViewController(viewModel: viewModel,
                                                    windowUUID: windowUUID)
        controller.onViewWillAppear = { [weak self] in
            self?.navigationHandler?.setNavigationBarHidden(true)
        }
        controller.onViewWillDisappear = { [weak self] in
            if !(controller.transitionCoordinator?.isInteractive ?? false) {
                self?.navigationHandler?.setNavigationBarHidden(false)
            }
        }
        return controller
    }

    private func makeEditFolderController(for node: BookmarkFolderData?, folder: FxBookmarkNode) -> UIViewController {
        let viewModel = EditFolderViewModel(profile: profile,
                                            parentFolder: folder,
                                            folder: node)
        viewModel.onBookmarkSaved = { [weak self] in
            self?.reloadLastBookmarksController()
        }
        let controller = EditFolderViewController(viewModel: viewModel,
                                                  windowUUID: windowUUID)
        controller.onViewWillAppear = { [weak self] in
            self?.navigationHandler?.setNavigationBarHidden(true)
        }
        controller.onViewWillDisappear = { [weak self] in
            if !(controller.transitionCoordinator?.isInteractive ?? false) {
                self?.navigationHandler?.setNavigationBarHidden(false)
            }
        }
        return controller
    }

    private func reloadLastBookmarksController() {
        guard let rootBookmarkController = router.navigationController.viewControllers.last
                as? BookmarksViewController
        else { return }
        rootBookmarkController.reloadData()
    }
}
