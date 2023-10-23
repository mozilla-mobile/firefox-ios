// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Shared

protocol FakespotCoordinatorDelegate: AnyObject {
    // Define any coordinator delegate methods
}

protocol FakespotViewControllerDelegate: AnyObject {
    func fakespotControllerDidDismiss()
}

class FakespotCoordinator: BaseCoordinator, FakespotViewControllerDelegate, FeatureFlaggable {
    weak var parentCoordinator: ParentCoordinatorDelegate?
    private var profile: Profile

    private var isOptedIn: Bool {
        return profile.prefs.boolForKey(PrefsKeys.Shopping2023OptIn) ?? false
    }

    init(router: Router, profile: Profile = AppContainer.shared.resolve()) {
        self.profile = profile
        super.init(router: router)
    }

    func start(productURL: URL) {
        let environment = featureFlags.isCoreFeatureEnabled(.useStagingFakespotAPI) ? FakespotEnvironment.staging : .prod
        let viewModel = FakespotViewModel(shoppingProduct: ShoppingProduct(
            url: productURL,
            client: FakespotClient(environment: environment)))
        let fakespotViewController = FakespotViewController(viewModel: viewModel)
        fakespotViewController.delegate = self
        if let sheet = fakespotViewController.sheetPresentationController {
            sheet.detents = [.medium(), .large()]

            // Show onboarding in full height
            if !isOptedIn {
                sheet.selectedDetentIdentifier = .large
            }
        }
        router.present(fakespotViewController, animated: true)
    }

    func fakespotControllerDidDismiss() {
        router.dismiss(animated: true, completion: nil)
        parentCoordinator?.didFinish(from: self)
    }
}
