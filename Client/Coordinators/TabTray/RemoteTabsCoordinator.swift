// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

protocol RemoteTabsCoordinatorDelegate: AnyObject {
    func openInNewTab(_ url: URL, isPrivate: Bool)
    func presentFirefoxAccountSignIn()
}

class RemoteTabsCoordinator: BaseCoordinator, RemoteTabsCoordinatorDelegate, QRCodeNavigationHandler, ParentCoordinatorDelegate {
    // MARK: - Properties
    private weak var parentCoordinator: TabTrayCoordinatorDelegate?
    private let profile: Profile

    // MARK: - Initializers

    init(profile: Profile,
         parentCoordinator: TabTrayCoordinatorDelegate?,
         router: Router
    ) {
        self.profile = profile
        self.parentCoordinator = parentCoordinator
        super.init(router: router)
    }

    // MARK: - RemoteTabsNavigationHandler
    func openInNewTab(_ url: URL, isPrivate: Bool) {}

    func presentFirefoxAccountSignIn() {
        let fxaParams = FxALaunchParams(entrypoint: .homepanel, query: [:])
        let viewController = FirefoxAccountSignInViewController(profile: profile,
                                                                parentType: .tabTray,
                                                                deepLinkParams: fxaParams)
        viewController.qrCodeNavigationHandler = self
        router.present(viewController)
    }

    // MARK: - RemoteTabsNavigationHandler
    func showQRCode(delegate: QRCodeViewControllerDelegate, rootNavigationController: UINavigationController?) {
        var coordinator: QRCodeCoordinator
        if let qrCodeCoordinator = childCoordinators.first(where: { $0 is QRCodeCoordinator }) as? QRCodeCoordinator {
            coordinator = qrCodeCoordinator
        } else {
            let router = rootNavigationController != nil ? DefaultRouter(navigationController: rootNavigationController!) : router
            coordinator = QRCodeCoordinator(parentCoordinator: self, router: router)
            add(child: coordinator)
        }
        coordinator.showQRCode(delegate: delegate)
    }

    func didFinish(from childCoordinator: Coordinator) {
        remove(child: childCoordinator)
    }
}
