/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

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
            
            guard let oldViewController = oldValue else {
                return
            }
            oldViewController.willMove(toParent: nil)
            oldViewController.view.removeFromSuperview()
            oldViewController.removeFromParent()
        }
    }
    
    override func prepareInterfaceForExtensionConfiguration() {
        self.presenter?.extensionConfigurationRequested()
    }
    
    /*
     Prepare your UI to list available credentials for the user to choose from. The items in
     'serviceIdentifiers' describe the service the user is logging in to, so your extension can
     prioritize the most relevant credentials in the list.
     */
    
    override func prepareCredentialList(for serviceIdentifiers: [ASCredentialServiceIdentifier]) {
        if false { // LAContext().canEvaluatePolicy(.deviceOwnerAuthentication, error: nil) {
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
        if false { // LAContext().canEvaluatePolicy(.deviceOwnerAuthentication, error: nil) {
            self.presenter?.credentialProvisionRequested(for: credentialIdentity)
        } else {
            self.extensionContext.cancelRequest(withError: ASExtensionError(.userInteractionRequired))
        }
    }
    
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
            let error = NSError(domain: ASExtensionErrorDomain, code: ASExtensionError.Code.userCanceled.rawValue, userInfo: nil)
            self.extensionContext.cancelRequest(withError: error) // This does not actually work - the extension is still selected
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
    func credentialPasscodeRequirementViewControllerDidCancel() {
        self.currentViewController?.dismiss(animated: false) {
            let error = NSError(domain: ASExtensionErrorDomain, code: ASExtensionError.Code.userCanceled.rawValue, userInfo: nil)
            self.extensionContext.cancelRequest(withError: error)
        }
    }
}
