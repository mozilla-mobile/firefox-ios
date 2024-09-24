// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Storage
import Common

import enum MozillaAppServices.BookmarkNodeType

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
            navigationHandler?.setNavigationBarHidden(true)
            let detailController = EditBookmarkViewController(node: node,
                                                              parentFolder: folder,
                                                              windowUUID: windowUUID)
            detailController.onViewDisappear = { [weak self] in
                self?.navigationHandler?.setNavigationBarHidden(false)
            }
            router.push(detailController)
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

    func shareLibraryItem(url: URL, sourceView: UIView) {
        navigationHandler?.shareLibraryItem(url: url, sourceView: sourceView)
    }
}
