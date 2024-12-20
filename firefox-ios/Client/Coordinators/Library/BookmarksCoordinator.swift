// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
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

    func showSignIn()
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
                            QRCodeNavigationHandler,
                            BookmarksRefactorFeatureFlagProvider,
                            ParentCoordinatorDelegate {
    // MARK: - Properties

    private let profile: Profile
    private weak var parentCoordinator: LibraryCoordinatorDelegate?
    private weak var navigationHandler: LibraryNavigationHandler?
    private var fxAccountViewController: FirefoxAccountSignInViewController?
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
                                                             parentBookmarkFolder: folder) {
                completion?()
            }
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

    func showSignIn() {
        let controller = makeSignInController()
        router.present(controller)
    }

    func shareLibraryItem(url: URL, sourceView: UIView) {
        navigationHandler?.shareLibraryItem(url: url, sourceView: sourceView)
    }

    // MARK: - QRCodeNavigationHandler

    func showQRCode(delegate: QRCodeViewControllerDelegate, rootNavigationController: UINavigationController?) {
        var coordinator: QRCodeCoordinator
        if let qrCodeCoordinator = childCoordinators.first(where: { $0 is QRCodeCoordinator }) as? QRCodeCoordinator {
            coordinator = qrCodeCoordinator
        } else {
            if rootNavigationController != nil {
                coordinator = QRCodeCoordinator(
                    parentCoordinator: self,
                    router: DefaultRouter(navigationController: rootNavigationController!)
                )
            } else {
                coordinator = QRCodeCoordinator(
                    parentCoordinator: self,
                    router: router
                )
            }
            add(child: coordinator)
        }
        coordinator.showQRCode(delegate: delegate)
    }

    // MARK: - ParentCoordinatorDelegate

    func didFinish(from childCoordinator: Coordinator) {
        remove(child: childCoordinator)
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
        if node.type == .bookmark {
            return makeEditBookmarkController(for: node, folder: folder)
        }
        if node.type == .folder {
            return makeEditFolderController(for: node, folder: folder)
        }
        return UIViewController()
    }

    private func makeEditBookmarkController(for node: FxBookmarkNode?, folder: FxBookmarkNode) -> UIViewController {
        let viewModel = EditBookmarkViewModel(parentFolder: folder, node: node, profile: profile)
        viewModel.onBookmarkSaved = { [weak self] in
            self?.reloadLastBookmarksController()
        }
        viewModel.bookmarkCoordinatorDelegate = self
        setBackBarButtonItemTitle(viewModel.backNavigationButtonTitle())
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

    private func makeEditFolderController(for node: FxBookmarkNode?, folder: FxBookmarkNode) -> UIViewController {
        let viewModel = EditFolderViewModel(profile: profile,
                                            parentFolder: folder,
                                            folder: node)
        viewModel.onBookmarkSaved = { [weak self] in
            self?.reloadLastBookmarksController()
        }
        setBackBarButtonItemTitle("")
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

    private func makeSignInController() -> UIViewController {
        let fxaParams = FxALaunchParams(entrypoint: .libraryPanel, query: [:])
        let viewController = FirefoxAccountSignInViewController(profile: profile,
                                                                parentType: .library,
                                                                deepLinkParams: fxaParams,
                                                                windowUUID: windowUUID)
        viewController.qrCodeNavigationHandler = self
        let buttonItem = UIBarButtonItem(
            title: .CloseButtonTitle,
            style: .plain,
            target: self,
            action: #selector(dismissFxAViewController)
        )
        viewController.navigationItem.leftBarButtonItem = buttonItem
        let navController = ThemedNavigationController(rootViewController: viewController, windowUUID: windowUUID)
        fxAccountViewController = viewController
        return navController
    }

    private func reloadLastBookmarksController() {
        guard let rootBookmarkController = router.navigationController.viewControllers.last
                as? BookmarksViewController
        else { return }
        rootBookmarkController.reloadData()
    }

    /// Sets the back button title for the controller
    ///
    /// It has to be done here and not in the detail controller directly, otherwise it won't take place the modification.
    private func setBackBarButtonItemTitle(_ title: String) {
        let backBarButton = UIBarButtonItem(title: title)
        router.navigationController.viewControllers.last?.navigationItem.backBarButtonItem = backBarButton
    }

    @objc
    private func dismissFxAViewController() {
        fxAccountViewController?.dismissVC()
        fxAccountViewController = nil
    }
}
