//
//  CredentialProviderViewController.swift
//  CredentialProvider
//
//  Created by Stefan Arentz on 2021-05-10.
//  Copyright © 2021 Mozilla. All rights reserved.
//

import AuthenticationServices

import Shared
import Storage
import Sync


class CredentialProviderViewController: ASCredentialProviderViewController {
    var profile = ExtensionProfile(localName: "profile")
//    var profile = LightProfile(localName: "profile")

    private var currentViewController: UIViewController? {
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
        displayWelcome()
        displayNotLoggedInMessage()
    }
    
    /*
     Prepare your UI to list available credentials for the user to choose from. The items in
     'serviceIdentifiers' describe the service the user is logging in to, so your extension can
     prioritize the most relevant credentials in the list.
     */
    override func prepareCredentialList(for serviceIdentifiers: [ASCredentialServiceIdentifier]) {
        
    }
    
    //     Implement this method if your extension supports showing credentials in the QuickType bar.
    //     When the user selects a credential from your app, this method will be called with the
    //     ASPasswordCredentialIdentity your app has previously saved to the ASCredentialIdentityStore.
    //     Provide the password by completing the extension request with the associated ASPasswordCredential.
    //     If using the credential would require showing custom UI for authenticating the user, cancel
    //     the request with error code ASExtensionError.userInteractionRequired.
    
    override func provideCredentialWithoutUserInteraction(for credentialIdentity: ASPasswordCredentialIdentity) {
//        let databaseIsUnlocked = false
//        if (databaseIsUnlocked) {
//            let passwordCredential = ASPasswordCredential(user: "j_appleseed", password: "apple1234")
//            self.extensionContext.completeRequest(withSelectedCredential: passwordCredential, completionHandler: nil)
//        } else {
//            self.extensionContext.cancelRequest(withError: NSError(domain: ASExtensionErrorDomain, code:ASExtensionError.userInteractionRequired.rawValue))
//        }
        

        let openError = self.profile.logins.reopenIfClosed()
        if let error = openError {
            
        } else if let id = credentialIdentity.recordIdentifier {
            
            profile.logins.get(id: id).upon { result in
                switch result {
                case .failure(_):
                    ()
                case .success(let record):
                    if let passwordCredential = record?.passwordCredential {
                        self.extensionContext.completeRequest(withSelectedCredential: passwordCredential, completionHandler: nil)
                    } else {
                        self.extensionContext.cancelRequest(withError: NSError(domain: ASExtensionErrorDomain, code:ASExtensionError.userInteractionRequired.rawValue))
                    }
                }
            }
        }
    }
    
    
    
    //     Implement this method if provideCredentialWithoutUserInteraction(for:) can fail with
    //     ASExtensionError.userInteractionRequired. In this case, the system may present your extension's
    //     UI and call this method. Show appropriate UI for authenticating the user then provide the password
    //     by completing the extension request with the associated ASPasswordCredential.
    
    override func prepareInterfaceToProvideCredential(for credentialIdentity: ASPasswordCredentialIdentity) {
        
    }
    
    
    @IBAction func cancel(_ sender: AnyObject?) {
        self.extensionContext.cancelRequest(withError: NSError(domain: ASExtensionErrorDomain, code: ASExtensionError.userCanceled.rawValue))
    }
    
    @IBAction func passwordSelected(_ sender: AnyObject?) {
        let passwordCredential = ASPasswordCredential(user: "j_appleseed", password: "apple1234")
        self.extensionContext.completeRequest(withSelectedCredential: passwordCredential, completionHandler: nil)
    }
}

extension CredentialProviderViewController: CredentialProviderViewProtocol {
    func displayWelcome() {
        let welcomeView = UIStoryboard(name: "CredentialWelcome", bundle: nil)
            .instantiateViewController(withIdentifier: "welcome")
        self.currentViewController = welcomeView
    }
    
    func displayItemList() {
        let viewController = UIStoryboard(name: "ItemList", bundle: nil)
            .instantiateViewController(withIdentifier: "itemlist")
        
        self.currentViewController = UINavigationController(rootViewController: viewController)
    }
    
    private func displayNotLoggedInMessage() {
        displayAlertController(
            buttons: [AlertActionButtonConfiguration(
                        title: "OK",
                        style: UIAlertAction.Style.default)],
            title: "NOt signed in",
            message: String(format: "needs sign in", "prodname", "maess"),
            style: .alert,
            barButtonItem: nil)
    }
}

@available(iOS 12, *)
protocol CredentialProviderViewProtocol: AnyObject, AlertControllerView {
    var extensionContext: ASCredentialProviderExtensionContext { get }
    
    func displayWelcome()
    func displayItemList()
}

struct AlertActionButtonConfiguration {
    let title: String
    //    let tapObserver: AnyObserver<Void>?
    let style: UIAlertAction.Style
    let checked: Bool
    
    init(title: String, style: UIAlertAction.Style) {
        self.init(title: title, style: style, checked: false)
    }
    
    init(title: String, style: UIAlertAction.Style, checked: Bool) {
        self.title = title
        self.style = style
        self.checked = checked
    }
}

protocol AlertControllerView {
    func displayAlertController(buttons: [AlertActionButtonConfiguration],
                                title: String?,
                                message: String?,
                                style: UIAlertController.Style,
                                barButtonItem: UIBarButtonItem?)
}

extension UIViewController: AlertControllerView {
    func displayAlertController(buttons: [AlertActionButtonConfiguration],
                                title: String?,
                                message: String?,
                                style: UIAlertController.Style,
                                barButtonItem: UIBarButtonItem?) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: style)
        
        if let barButtonItem = barButtonItem {
            let presentationController = alertController.popoverPresentationController
            presentationController?.barButtonItem = barButtonItem
        }
        
        for buttonConfig in buttons {
            let action = UIAlertAction(title: buttonConfig.title, style: buttonConfig.style) { _ in
                //                buttonConfig.tapObserver?.onNext(())
                //                buttonConfig.tapObserver?.onCompleted()
            }
            
            action.setValue(buttonConfig.checked, forKey: "checked")
            
            alertController.addAction(action)
        }
        
        DispatchQueue.main.async {
            self.present(alertController, animated: true)
        }
    }
}
