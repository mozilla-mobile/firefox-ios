// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

protocol FakespotCoordinatorDelegate: AnyObject {
    // Define any coordinator delegate methods here
}

class FakespotCoordinator: BaseCoordinator {
    weak var parentCoordinator: FakespotCoordinatorDelegate?
    weak var delegate: FakespotCoordinatorDelegate?

    let fakespotViewController: FakespotViewController
    let viewModel: FakespotViewModel

    init(router: Router) {
        viewModel = FakespotViewModel()
        fakespotViewController = FakespotViewController(viewModel: viewModel)
        super.init(router: router)
    }

    func start() {
        if #available(iOS 15.0, *) {
            if let sheet = fakespotViewController.sheetPresentationController {
                sheet.detents = [.medium(), .large()]
            }
        }
        router.present(fakespotViewController, animated: true)
    }
}
