// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common

final class ContextMenuCoordinator: BaseCoordinator {
    weak var parentCoordinator: ParentCoordinatorDelegate?
    private let windowUUID: WindowUUID
    private let configuration: ContextMenuConfiguration

    init(
        configuration: ContextMenuConfiguration,
        router: Router,
        windowUUID: WindowUUID
    ) {
        self.configuration = configuration
        self.windowUUID = windowUUID
        super.init(router: router)
    }

    func start() {
        let state = ContextMenuState(configuration: configuration, windowUUID: windowUUID)
        let viewModel = PhotonActionSheetViewModel(
            actions: state.actions,
            site: state.site,
            modalStyle: .overFullScreen
        )
        let sheet = PhotonActionSheet(viewModel: viewModel, windowUUID: windowUUID)
        sheet.modalTransitionStyle = .crossDissolve
        router.present(sheet)
    }

    func dismissFlow() {
        router.dismiss(animated: true, completion: nil)
        parentCoordinator?.didFinish(from: self)
    }
}
