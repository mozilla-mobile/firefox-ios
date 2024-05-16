// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common

class RemoteTabsCoordinator: BaseCoordinator,
                             RemoteTabsPanelDelegate,
                             ParentCoordinatorDelegate,
                             QRCodeNavigationHandler {
    // MARK: - Properties
    private let profile: Profile
    private var fxAccountViewController: FirefoxAccountSignInViewController?
    private var applicationHelper: ApplicationHelper
    let windowUUID: WindowUUID

    weak var parentCoordinator: ParentCoordinatorDelegate?

    // MARK: - Initializers

    init(profile: Profile,
         router: Router,
         windowUUID: WindowUUID,
         applicationHelper: ApplicationHelper = DefaultApplicationHelper()
    ) {
        self.profile = profile
        self.applicationHelper = applicationHelper
        self.windowUUID = windowUUID
        super.init(router: router)
    }

    // MARK: - RemoteTabsNavigationHandler
    func presentFirefoxAccountSignIn() {
        let fxaParams = FxALaunchParams(entrypoint: .homepanel, query: [:])
        let viewController = FirefoxAccountSignInViewController(profile: profile,
                                                                parentType: .tabTray,
                                                                deepLinkParams: fxaParams,
                                                                windowUUID: windowUUID)
        fxAccountViewController = viewController
        fxAccountViewController?.qrCodeNavigationHandler = self
        let buttonItem = UIBarButtonItem(
            title: .CloseButtonTitle,
            style: .plain,
            target: self,
            action: #selector(dismissFxAViewController)
        )
        fxAccountViewController?.navigationItem.leftBarButtonItem = buttonItem
        let navController = ThemedNavigationController(rootViewController: viewController, windowUUID: windowUUID)
        router.present(navController)
    }

    func presentFxAccountSettings() {
        TelemetryWrapper.recordEvent(category: .action,
                                     method: .tap,
                                     object: .syncSignIn)
        parentCoordinator?.didFinish(from: self)
        let urlString = URL.mozInternalScheme + "://deep-link?url=/settings/fxa"
        guard let url = URL(string: urlString) else { return }
        applicationHelper.open(url, inWindow: windowUUID)
    }

    @objc
    func dismissFxAViewController() {
        fxAccountViewController?.dismissVC()
    }

    func didFinish(from childCoordinator: Coordinator) {
        remove(child: childCoordinator)
    }

    // MARK: - QRCodeNavigationHandler
    func showQRCode(delegate: QRCodeViewControllerDelegate, rootNavigationController: UINavigationController?) {
        var coordinator: QRCodeCoordinator
        if let qrCodeCoordinator = childCoordinators.first(where: { $0 is QRCodeCoordinator }) as? QRCodeCoordinator {
            coordinator = qrCodeCoordinator
        } else {
            if rootNavigationController != nil {
                coordinator = QRCodeCoordinator(
                    parentCoordinator: self,
                    router: DefaultRouter(navigationController: rootNavigationController!)
                )
            } else {
                coordinator = QRCodeCoordinator(
                    parentCoordinator: self,
                    router: router
                )
            }
            add(child: coordinator)
        }
        coordinator.showQRCode(delegate: delegate)
    }
}
