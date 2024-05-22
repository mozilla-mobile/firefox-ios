// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

protocol QRCodeDismissHandler: AnyObject {
    /// Dismisses the current presented QRCodeViewController
    func dismiss(_ completion: (() -> Void)?)
}

class QRCodeCoordinator: BaseCoordinator, QRCodeDismissHandler {
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
        qrCodeViewController.dismissHandler = self
        let navigationController = QRCodeNavigationController(rootViewController: qrCodeViewController)
        router.present(navigationController, animated: true) { [weak self] in
            guard let self = self else { return }
            self.dismiss()
        }
    }

    // MARK: - QRCodeDismissHandler
    func dismiss(_ completion: (() -> Void)?) {
        router.dismiss(animated: true, completion: completion)
        dismiss()
    }

    // MARK: - Private
    private func dismiss() {
        parentCoordinator?.didFinish(from: self)
    }
}
