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
    /*
     Prepare your UI to list available credentials for the user to choose from. The items in
     'serviceIdentifiers' describe the service the user is logging in to, so your extension can
     prioritize the most relevant credentials in the list.
    */
    
    override func prepareCredentialList(for serviceIdentifiers: [ASCredentialServiceIdentifier]) {
        /* This code is only here now to test if things properly link and compile. Logins should be available through profile.logins
         
         let profile = ExtensionProfile(localName: "profile")
         print("This is the \(profile.localName()) profile")
         print (profile.logins)
         */
        //TODO: check if data base is locked and provide authentication functionality
        navigateToCredentialList()
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
        let databaseIsUnlocked = true
        if (databaseIsUnlocked) {
            let passwordCredential = ASPasswordCredential(user: "j_appleseed", password: "apple1234")
            self.extensionContext.completeRequest(withSelectedCredential: passwordCredential, completionHandler: nil)
        } else {
            self.extensionContext.cancelRequest(withError: NSError(domain: ASExtensionErrorDomain, code:ASExtensionError.userInteractionRequired.rawValue))
        }
    }
    

    /*
     Implement this method if provideCredentialWithoutUserInteraction(for:) can fail with
     ASExtensionError.userInteractionRequired. In this case, the system may present your extension's
     UI and call this method. Show appropriate UI for authenticating the user then provide the password
     by completing the extension request with the associated ASPasswordCredential.

     */
    
    override func prepareInterfaceToProvideCredential(for credentialIdentity: ASPasswordCredentialIdentity) {
    }
    
    
    private func navigateToCredentialList() {
        let storyboard = UIStoryboard(name: "CredentialList", bundle: nil)
        let credentialListVC = storyboard.instantiateViewController(withIdentifier: "itemlist")
        self.currentViewController = UINavigationController(rootViewController: credentialListVC)
    }

    @IBAction func cancel(_ sender: AnyObject?) {
        self.extensionContext.cancelRequest(withError: NSError(domain: ASExtensionErrorDomain, code: ASExtensionError.userCanceled.rawValue))
    }

    @IBAction func passwordSelected(_ sender: AnyObject?) {
        let passwordCredential = ASPasswordCredential(user: "j_appleseed", password: "apple1234")
        self.extensionContext.completeRequest(withSelectedCredential: passwordCredential, completionHandler: nil)
    }

}
