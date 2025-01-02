// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common

protocol ContextMenuCoordinatorDelegate: AnyObject {
    func dismissFlow()
}

final class ContextMenuCoordinator: BaseCoordinator, ContextMenuCoordinatorDelegate {
    weak var parentCoordinator: ParentCoordinatorDelegate?

    private let windowUUID: WindowUUID
    private let configuration: ContextMenuConfiguration
    /// Used to call bookmark methods in BVC
    private let bookmarksHandlerDelegate: BookmarksHandlerDelegate

    init(
        configuration: ContextMenuConfiguration,
        router: Router,
        windowUUID: WindowUUID,
        bookmarksHandlerDelegate: BookmarksHandlerDelegate
    ) {
        self.configuration = configuration
        self.windowUUID = windowUUID
        self.bookmarksHandlerDelegate = bookmarksHandlerDelegate
        super.init(router: router)
    }

    func start() {
        let state = ContextMenuState(
            bookmarkDelegate: bookmarksHandlerDelegate,
            configuration: configuration,
            windowUUID: windowUUID
        )
        let viewModel = PhotonActionSheetViewModel(
            actions: state.actions,
            site: state.site,
            modalStyle: .overFullScreen
        )
        let sheet = PhotonActionSheet(viewModel: viewModel, windowUUID: windowUUID)
        sheet.coordinator = self
        sheet.modalTransitionStyle = .crossDissolve
        router.present(sheet)
    }

    func dismissFlow() {
        router.dismiss(animated: true, completion: nil)
        parentCoordinator?.didFinish(from: self)
    }
}
