// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Shared

protocol FakespotCoordinatorDelegate: AnyObject {
    // Define any coordinator delegate methods
}

class FakespotCoordinator: BaseCoordinator, FeatureFlaggable {
    weak var parentCoordinator: ParentCoordinatorDelegate?
    private var profile: Profile
    private let tabManager: TabManager

    private var isOptedIn: Bool {
        return profile.prefs.boolForKey(PrefsKeys.Shopping2023OptIn) ?? false
    }

    init(router: Router,
         profile: Profile = AppContainer.shared.resolve(),
         tabManager: TabManager) {
        self.tabManager = tabManager
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

    func closeSidebar(sidebarContainer: SidebarEnabledViewProtocol,
                      parentViewController: UIViewController) {
        sidebarContainer.hideSidebar(parentViewController)
        dismissModal(animated: true)
    }

    func dismissModal(animated: Bool) {
        router.dismiss(animated: animated, completion: nil)
        parentCoordinator?.didFinish(from: self)
    }

    func updateSidebar(productURL: URL,
                       sidebarContainer: SidebarEnabledViewProtocol,
                       parentViewController: UIViewController) {
        let viewModel = createFakespotViewModel(productURL: productURL)
        sidebarContainer.updateSidebar(viewModel, parentViewController: parentViewController)
    }

    private func createFakespotViewController(productURL: URL) -> FakespotViewController {
        let viewModel = createFakespotViewModel(productURL: productURL)
        let fakespotViewController = FakespotViewController(viewModel: viewModel, tabManager: tabManager)
        return fakespotViewController
    }

    private func createFakespotViewModel(productURL: URL) -> FakespotViewModel {
        let environment = featureFlags.isCoreFeatureEnabled(.useStagingFakespotAPI) ? FakespotEnvironment.staging : .prod
        let viewModel = FakespotViewModel(shoppingProduct: ShoppingProduct(
            url: productURL,
            client: FakespotClient(environment: environment)), tabManager: tabManager)
        return viewModel
    }
}
