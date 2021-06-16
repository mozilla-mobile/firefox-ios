/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import AuthenticationServices
import SwiftKeychainWrapper

@available(iOS 12, *)
class CredentialProviderPresenter {
    weak var view: CredentialProviderViewProtocol?
    private let profile: Profile
    
    init(view: CredentialProviderViewProtocol, profile: Profile = ExtensionProfile(localName: "profile")) {
        self.view = view
        self.profile = profile
    }
    
    func extensionConfigurationRequested() {
        view?.showWelcome()
        if let openError = self.profile.logins.reopenIfClosed() {
            displayNotLoggedInMessage()
        } else {
            self.view?.displaySpinner(message: "Syncing your logins")
            profile.syncCredentialIdentities().upon { result in
                sleep(2)
                self.view?.hideSpinner(completionMessage: "Done Syncing your logins")
                self.cancelWith(.userCanceled)
            }
        }
    }
    
    func credentialProvisionRequested(for credentialIdentity: ASPasswordCredentialIdentity) {
        if self.profile.logins.reopenIfClosed() != nil {
            cancelWith(.failed)
        } else if let id = credentialIdentity.recordIdentifier {
            
            profile.logins.get(id: id).upon { [weak self] result in
                switch result {
                case .failure:
                    self?.cancelWith(.failed)
                case .success(let record):
                    if let passwordCredential = record?.passwordCredential {
                        self?.view?.extensionContext.completeRequest(withSelectedCredential: passwordCredential, completionHandler: nil)
                    } else {
                        self?.cancelWith(.userInteractionRequired)
                    }
                }
            }
        }
    }
    
    fileprivate func showCredentialList(for serviceIdentifiers: [ASCredentialServiceIdentifier]) {
        if let openError = self.profile.logins.reopenIfClosed() {
            self.cancelWith(.failed)
        } else {
            self.profile.logins.list().upon { [weak self] result in
                switch result {
                case .failure: self?.cancelWith(.failed)
                case .success(let loginRecods):
                    DispatchQueue.main.async {
                        self?.view?.show(itemList: loginRecods.map { ($0.passwordCredentialIdentity, $0.passwordCredential) })
                    }
                }
            }
        }
    }
    
    func credentialList(for serviceIdentifiers: [ASCredentialServiceIdentifier]) {
        view?.showWelcome()
        
        guard let authInfo = KeychainWrapper.sharedAppContainerKeychain.authenticationInfo(), authInfo.requiresValidation() else {
            showCredentialList(for: serviceIdentifiers)
            return
        }
        
        AppAuthenticator.presentAuthenticationUsingInfo(
            authInfo,
            touchIDReason: .AuthenticationLoginsTouchReason,
            success: { self.showCredentialList(for: serviceIdentifiers)},
            cancel: { self.cancelWith(.userCanceled) },
            fallback: { [weak self] in
                self?.view?.showPassword { isOk in
                    if isOk { self?.showCredentialList(for: serviceIdentifiers) }
                }
            })
    }
    
    func prepareAuthentication(for credentialIdentity: ASPasswordCredentialIdentity) { }
}

@available(iOS 12, *)
private extension CredentialProviderPresenter {
    
    func displayNotLoggedInMessage() {
        view?.displayAlertController(
            buttons: [
                AlertActionButtonConfiguration(
                    title: "OK",
                    tapAction: { [weak self] in self?.cancelWith(.userCanceled) },
                    style: .default)
            ],
            title: "NOt signed in",
            message: String(format: "needs sign in", "prodname", "maess"),
            style: .alert,
            barButtonItem: nil)
    }
    
    func cancelWith(_ errorCode: ASExtensionError.Code) {
        let error = NSError(domain: ASExtensionErrorDomain,
                            code: errorCode.rawValue,
                            userInfo: nil)
        
        self.view?.extensionContext.cancelRequest(withError: error)
    }
}
