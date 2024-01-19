// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import AuthenticationServices
import LocalAuthentication

import Shared
import Storage
import Sync

protocol CredentialProviderViewProtocol: AnyObject, AlertControllerView {
    var extensionContext: ASCredentialProviderExtensionContext { get }

    func showWelcome()
    func showPasscodeRequirement()
    func show(itemList: [(ASPasswordCredentialIdentity, ASPasswordCredential)])
}

class CredentialProviderViewController: ASCredentialProviderViewController {
    private var presenter: CredentialProviderPresenter?
    private let appAuthenticator = AppAuthenticator()

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.presenter = CredentialProviderPresenter(view: self)
    }

    var currentViewController: UIViewController? {
        didSet {
            if let currentViewController = self.currentViewController {
                self.addChild(currentViewController)
                currentViewController.view.frame = self.view.bounds
                self.view.addSubview(currentViewController.view)
                currentViewController.didMove(toParent: self)
            }

            guard let oldViewController = oldValue else { return }
            oldViewController.willMove(toParent: nil)
            oldViewController.view.removeFromSuperview()
            oldViewController.removeFromParent()
        }
    }

    override func prepareInterfaceForExtensionConfiguration() {
        if appAuthenticator.canAuthenticateDeviceOwner {
            self.presenter?.extensionConfigurationRequested()
        } else {
            self.presenter?.showPasscodeRequirement()
        }
    }

    /*
     Prepare your UI to list available credentials for the user to choose from. The items in
     'serviceIdentifiers' describe the service the user is logging in to, so your extension can
     prioritize the most relevant credentials in the list.
     */

    override func prepareCredentialList(for serviceIdentifiers: [ASCredentialServiceIdentifier]) {
        if appAuthenticator.canAuthenticateDeviceOwner {
            self.presenter?.credentialList(for: serviceIdentifiers)
        } else {
            self.presenter?.showPasscodeRequirement()
        }
    }

    /*
     Implement this method if your extension supports showing credentials in the QuickType bar.
     When the user selects a credential from your app, this method will be called with the
     ASPasswordCredentialIdentity your app has previously saved to the ASCredentialIdentityStore.
     Provide the password by completing the extension request with the associated ASPasswordCredential.
     If using the credential would require showing custom UI for authenticating the user, cancel
     the request with error code ASExtensionError.userInteractionRequired.
     */

    override func provideCredentialWithoutUserInteraction(for credentialIdentity: ASPasswordCredentialIdentity) {
        if appAuthenticator.canAuthenticateDeviceOwner {
            self.presenter?.credentialProvisionRequested(for: credentialIdentity)
        } else {
            self.extensionContext.cancelRequest(withError: ASExtensionError(.userInteractionRequired))
        }
    }

    /*! @abstract Prepare the view controller to show user interface for providing the user-requested credential.
     @param credentialIdentity the credential identity for which a credential should be provided.
     @discussion The system calls this method when your extension cannot provide the requested credential 
     without user interaction. Set up the view controller for any user interaction required to provide the
     requested credential only. The user interaction should be limited in nature to operations required
     for providing the requested credential. An example is showing an authentication UI to unlock
     the user's passwords database.
     Call -[ASCredentialProviderExtensionContext completeRequestWithSelectedCredential:completionHandler:] to
     provide the credential. If an error occurs, call -[ASCredentialProviderExtensionContext cancelRequestWithError:]
     and pass an error with domain ASExtensionErrorDomain and an appropriate error code from ASExtensionErrorCode.
     For example, if the credential identity cannot be found in the database, pass an error with
     code ASExtensionErrorCodeCredentialIdentityNotFound.
     */

    override func prepareInterfaceToProvideCredential(for credentialIdentity: ASPasswordCredentialIdentity) {
        self.presenter?.showPasscodeRequirement()
    }
}

extension CredentialProviderViewController: CredentialProviderViewProtocol {
    func showWelcome() {
        let welcomeVC = CredentialWelcomeViewController()
        welcomeVC.delegate = self
        self.currentViewController = welcomeVC
    }

    func showPasscodeRequirement() {
        let vc = CredentialPasscodeRequirementViewController()
        vc.delegate = self
        self.currentViewController = vc
    }

    func show(itemList: [(ASPasswordCredentialIdentity, ASPasswordCredential)]) {
        let credentialListVC = CredentialListViewController()
        credentialListVC.dataSource = itemList
        self.currentViewController = UINavigationController(rootViewController: credentialListVC)
    }
}

extension CredentialProviderViewController: CredentialWelcomeViewControllerDelegate {
    func credentialWelcomeViewControllerDidCancel() {
        self.currentViewController?.dismiss(animated: false) {
            // This does not actually work - the extension is still selected, file a bug with Apple?
            self.extensionContext.cancelRequest(withError: ASExtensionError(.userCanceled))
        }
    }

    func credentialWelcomeViewControllerDidProceed() {
        self.currentViewController?.dismiss(animated: false) {
            if self.presenter?.profile.logins.reopenIfClosed() != nil {
                self.extensionContext.cancelRequest(withError: ASExtensionError(.failed))
                return
            }
            self.presenter?.profile.syncCredentialIdentities().upon { result in
                self.extensionContext.completeExtensionConfigurationRequest()
            }
        }
    }
}

extension CredentialProviderViewController: CredentialPasscodeRequirementViewControllerDelegate {
    func credentialPasscodeRequirementViewControllerDidDismiss() {
        self.currentViewController?.dismiss(animated: false) {
            self.extensionContext.cancelRequest(withError: ASExtensionError(.userCanceled))
        }
    }
}
