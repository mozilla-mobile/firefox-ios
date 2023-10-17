// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

class QRCodeCoordinator: BaseCoordinator {
    private weak var parentCoordinator: ParentCoordinatorDelegate?

    init(
        parentCoordinator: ParentCoordinatorDelegate?,
        router: Router
    ) {
        self.parentCoordinator = parentCoordinator
        super.init(router: router)
    }

    func showQRCode(delegate: QRCodeViewControllerDelegate) {
        let qrCodeViewController = QRCodeViewController()
        qrCodeViewController.qrCodeDelegate = delegate
        let navigationController = QRCodeNavigationController(rootViewController: qrCodeViewController)
        router.present(navigationController, animated: true) { [weak self] in
            guard let self = self else { return }
            self.parentCoordinator?.didFinish(from: self)
        }
    }
}
