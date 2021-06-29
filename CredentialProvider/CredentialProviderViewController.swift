/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import AuthenticationServices

import Shared
import Storage
import Sync

@available(iOS 12, *)
protocol CredentialProviderViewProtocol: AnyObject, AlertControllerView, SpinnerAlertView {
    var extensionContext: ASCredentialProviderExtensionContext { get }

    func showWelcome()
    func showPassword(completion: @escaping (Bool) -> Void)
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
        self.presenter?.credentialList(for: serviceIdentifiers)
    }
    
    /*
     Implement this method if provideCredentialWithoutUserInteraction(for:) can fail with
     ASExtensionError.userInteractionRequired. In this case, the system may present your extension's
     UI and call this method. Show appropriate UI for authenticating the user then provide the password
     by completing the extension request with the associated ASPasswordCredential.
     */
    override func prepareInterfaceToProvideCredential(for credentialIdentity: ASPasswordCredentialIdentity) {
        self.presenter?.prepareAuthentication(for: credentialIdentity)
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
        self.presenter?.credentialProvisionRequested(for: credentialIdentity)
    }
}

extension CredentialProviderViewController: CredentialProviderViewProtocol {
    func showPassword(completion: @escaping (Bool) -> Void) {
        let passcodeVC = PasscodeEntryViewController(passcodeCompletion: completion)
        self.currentViewController = passcodeVC
    }
    
    func showWelcome() {
        let welcomeView = UIStoryboard(name: "CredentialWelcome", bundle: nil)
            .instantiateViewController(withIdentifier: "welcome")
        self.currentViewController = welcomeView
    }
    
    func show(itemList: [(ASPasswordCredentialIdentity, ASPasswordCredential)]) {
        let storyboard = UIStoryboard(name: "CredentialList", bundle: nil)
        let credentialListVC = storyboard.instantiateViewController(withIdentifier: "itemlist") as! CredentialListViewController
        credentialListVC.dataSource = itemList
        self.currentViewController = UINavigationController(rootViewController: credentialListVC)
    }
}
