// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

class RemoteTabsCoordinator: BaseCoordinator, RemoteTabsPanelDelegate {
    // MARK: - Properties
    private let profile: Profile
    private var fxAccountViewController: FirefoxAccountSignInViewController?
    private var applicationHelper: ApplicationHelper

    weak var parentCoordinator: ParentCoordinatorDelegate?
    weak var qrCodeNavigationHandler: QRCodeNavigationHandler?

    // MARK: - Initializers

    init(profile: Profile,
         router: Router,
         applicationHelper: ApplicationHelper = DefaultApplicationHelper()
    ) {
        self.profile = profile
        self.applicationHelper = applicationHelper
        super.init(router: router)
    }

    // MARK: - RemoteTabsNavigationHandler
    func presentFirefoxAccountSignIn() {
        let fxaParams = FxALaunchParams(entrypoint: .homepanel, query: [:])
        let viewController = FirefoxAccountSignInViewController(profile: profile,
                                                                parentType: .tabTray,
                                                                deepLinkParams: fxaParams)
        fxAccountViewController = viewController
        fxAccountViewController?.qrCodeNavigationHandler = qrCodeNavigationHandler
        let buttonItem = UIBarButtonItem(title: .CloseButtonTitle, style: .plain, target: self, action: #selector(dismissFxAViewController))
        fxAccountViewController?.navigationItem.leftBarButtonItem = buttonItem
        let navController = ThemedNavigationController(rootViewController: viewController)
        router.present(navController)
    }

    func presentFxAccountSettings() {
        parentCoordinator?.didFinish(from: self)
        let urlString = URL.mozInternalScheme + "://deep-link?url=/settings/fxa"
        guard let url = URL(string: urlString) else { return }
        applicationHelper.open(url)
    }

    @objc
    func dismissFxAViewController() {
        fxAccountViewController?.dismissVC()
    }

    func didFinish(from childCoordinator: Coordinator) {
        remove(child: childCoordinator)
    }
}
