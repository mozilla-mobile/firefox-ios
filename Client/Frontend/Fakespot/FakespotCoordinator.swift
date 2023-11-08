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
    func fakespotControllerDidDismiss(animated: Bool)
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

    func startModal(productURL: URL) {
        let viewController = createFakespotViewController(productURL: productURL)

        if let sheet = viewController.sheetPresentationController {
            sheet.detents = [.medium(), .large()]

            // Show onboarding in full height
            if !isOptedIn {
                sheet.selectedDetentIdentifier = .large
            }
        }
        router.present(viewController, animated: true)
    }

    func startSidebar(productURL: URL,
                      sidebarContainer: SidebarEnabledViewProtocol,
                      parentViewController: UIViewController) {
        let viewController = createFakespotViewController(productURL: productURL)
        sidebarContainer.showSidebar(viewController, parentViewController: parentViewController)
    }

    func fakespotControllerCloseSidebar(sidebarContainer: SidebarEnabledViewProtocol,
                                        parentViewController: UIViewController) {
        sidebarContainer.hideSidebar(parentViewController)
        fakespotControllerDidDismiss(animated: true)
    }

    func fakespotControllerDidDismiss(animated: Bool) {
        router.dismiss(animated: animated, completion: nil)
        parentCoordinator?.didFinish(from: self)
    }

    private func createFakespotViewController(productURL: URL) -> FakespotViewController {
        let environment = featureFlags.isCoreFeatureEnabled(.useStagingFakespotAPI) ? FakespotEnvironment.staging : .prod
        let viewModel = FakespotViewModel(shoppingProduct: ShoppingProduct(
            url: productURL,
            client: FakespotClient(environment: environment)))
        let fakespotViewController = FakespotViewController(viewModel: viewModel)
        fakespotViewController.delegate = self
        return fakespotViewController
    }
}
