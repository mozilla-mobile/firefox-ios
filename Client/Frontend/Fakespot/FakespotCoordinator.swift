// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

protocol FakespotCoordinatorDelegate: AnyObject {
    // Define any coordinator delegate methods
}

protocol FakespotViewControllerDelegate: AnyObject {
    func fakespotControllerDidDismiss()
}

class FakespotCoordinator: BaseCoordinator, FakespotViewControllerDelegate {
    weak var parentCoordinator: ParentCoordinatorDelegate?

    func start() {
        let viewModel = FakespotViewModel()
        let fakespotViewController = FakespotViewController(viewModel: viewModel)
        fakespotViewController.delegate = self
        if #available(iOS 15.0, *) {
            if let sheet = fakespotViewController.sheetPresentationController {
                sheet.detents = [.medium(), .large()]
            }
        }
        router.present(fakespotViewController, animated: true)
    }

    func fakespotControllerDidDismiss() {
        router.dismiss(animated: true, completion: nil)
        parentCoordinator?.didFinish(from: self)
    }
}
