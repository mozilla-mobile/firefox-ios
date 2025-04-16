// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import AuthenticationServices
import LocalAuthentication

import MozillaAppServices
import Shared
import Storage

protocol CredentialProviderViewProtocol: AnyObject {
    var extensionContext: ASCredentialProviderExtensionContext { get }

    func showWelcome()
    func showPasscodeRequirement()
    func show(itemList: [(ASPasswordCredentialIdentity, ASPasswordCredential)])
}

struct CredentialProvider {
    static var titleColor: UIColor? {
        return UIColor(named: "labelColor")
    }

    static var cellBackgroundColor: UIColor? {
        return UIColor(named: "credentialCellColor")
    }

    static var tableViewBackgroundColor: UIColor = .systemGroupedBackground

    static var welcomeScreenBackgroundColor: UIColor? {
        return UIColor(named: "launchScreenBackgroundColor")
    }
}

class CredentialProviderViewController: ASCredentialProviderViewController {
    private var presenter: CredentialProviderPresenter?
    private let appAuthenticator = AppAuthenticator()

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        // Initialize app services ( including NSS ). Must be called before any other calls to rust components.
        // In this case we need to call this before we try to decrypt any passwords, otherwise decryption fails.
        MozillaAppServices.initialize()
        self.presenter = CredentialProviderPresenter(view: self)
    }

    private var currentViewController: UIViewController? {
        didSet {
            if let currentViewController {
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

    /**
    Prepares the interface to display a list of credentials from which the user can select.

    - Parameter serviceIdentifiers: An array of service identifiers that provide a
     hint about the service for which the user needs credentials.

    The system calls this method to tell your extension’s view controller to prepare to present a list of credentials.
    After calling this method, the system presents the view controller to the user.

    Use the given `serviceIdentifiers` array to filter or prioritize the credentials to display.
    The service identifier array might be empty,
    but your extension should still show credentials from which the user can pick.
    */
    override func prepareCredentialList(for serviceIdentifiers: [ASCredentialServiceIdentifier]) {
        if appAuthenticator.canAuthenticateDeviceOwner {
            self.presenter?.credentialList(for: serviceIdentifiers)
        } else {
            self.presenter?.showPasscodeRequirement()
        }
    }

    /**
    Attempts to provide the user-requested credential with no further user interaction.

    - Parameter credentialIdentity: The credential identity for which a credential should be provided.

    When the user selects a credential identity from the QuickType bar,
    the system calls the `provideCredentialWithoutUserInteraction(for:)`
    method to ask your extension to provide the corresponding credential.

    Call the context’s `completeRequest(withSelectedCredential:completionHandler:)`
    method to provide the credential if the extension can do so without further user interaction.
    If not—for example, because the user must first unlock a password database—call the `cancelRequest(withError:)`
    method instead using an error with domain `ASExtensionErrorDomain` and code `userInteractionRequired`.
    In turn, the system calls your `prepareInterfaceToProvideCredential(for:)`
    method to give your extension a chance to present an interface to handle the needed user interaction.

    You can alternatively call the cancel method to indicate other error conditions using one of the codes in
    `ASExtensionError.Code`.
    */
    override func provideCredentialWithoutUserInteraction(for credentialIdentity: ASPasswordCredentialIdentity) {
        if appAuthenticator.canAuthenticateDeviceOwner {
            self.presenter?.credentialProvisionRequested(for: credentialIdentity)
        } else {
            self.presenter?.showPasscodeRequirement()
        }
    }

    /**
    Prepares the view controller to show user interface for providing the user-requested credential.

    - Parameter credentialIdentity: The credential identity for which a credential should be provided.

    The system calls this method when your extension can’t provide the requested credential without user interaction.
    Set up the view controller for any user interaction required to provide the requested credential.
    Limit user interaction to operations required for providing the requested credential,
    like showing an authentication UI to unlock the user’s passwords database.

    Call the context’s `completeRequest(withSelectedCredential:completionHandler:)` to provide the credential.
    Alternatively, if an error occurs, call `cancelRequest(withError:)` instead and pass an error with domain
    `ASExtensionErrorDomain` and an appropriate error code from `ASExtensionError.Code`.
    For example, if your app can’t find the credential identity in the database, pass an error with code
    `ASExtensionError.Code.credentialIdentityNotFound`.
    */
    override func prepareInterfaceToProvideCredential(for credentialIdentity: ASPasswordCredentialIdentity) {
        // Set up UI for allowing the user to fill the provided credential.
        showRetryAutofillAlert(for: credentialIdentity)
    }

    private func showRetryAutofillAlert(for credentialIdentity: ASPasswordCredentialIdentity) {
        let alertController = UIAlertController(
            title: .CredentialProviderRetryAlertTitle,
            message: .CredentialProviderRetryAlertMessage,
            preferredStyle: .alert
        )

        let retryAction = UIAlertAction(
            title: .CredentialProviderRetryAlertRetryActionTitle,
            style: .default
        ) { [unowned self] _ in
            provideCredentialWithoutUserInteraction(for: credentialIdentity)
        }
        alertController.addAction(retryAction)

        let cancelAction = UIAlertAction(
            title: .CredentialProviderRetryAlertCancelActionTitle,
            style: .cancel
        ) { [unowned self] _ in
            extensionContext.cancelRequest(withError: ASExtensionError(.userCanceled))
        }
        alertController.addAction(cancelAction)

        present(alertController, animated: true)
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
