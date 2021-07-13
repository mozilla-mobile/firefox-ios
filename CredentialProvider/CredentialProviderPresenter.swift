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
        if self.profile.logins.reopenIfClosed() != nil {
            // At this point there is nothing useful we can do if we cannot open the logins database. Worst case
            // we skip the synchronization and not all logins will be available to the user if they have changed
            // since the last time.
            return
        }
        
        profile.syncCredentialIdentities().upon { result in
            sleep(2)
            self.cancelWith(.userCanceled)
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
    

    func showCredentialList(for serviceIdentifiers: [ASCredentialServiceIdentifier]) {
    if self.profile.logins.reopenIfClosed() != nil {
            cancelWith(.failed)
        } else {
            profile.logins.list().upon {[weak self] result in
                switch result {
                case .failure:
                    self?.cancelWith(.failed)
                case .success(let loginRecords):
                    
                    var sortedLogins = loginRecords.sorted(by: <)
                    for (index, element) in sortedLogins.enumerated() {
                        if let identifier = serviceIdentifiers.first?.identifier.asURL?.domainURL.absoluteString.titleFromHostname, element.passwordCredentialIdentity.serviceIdentifier.identifier.contains(identifier) {
                            sortedLogins.remove(at: index)
                            sortedLogins.insert(element, at: 0)
                        }
                    }
                    
                    let dataSource = sortedLogins.map { ($0.passwordCredentialIdentity, $0.passwordCredential) }
                    DispatchQueue.main.async {
                        self?.view?.show(itemList: dataSource)
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
        
    func cancelWith(_ errorCode: ASExtensionError.Code) {
        let error = NSError(domain: ASExtensionErrorDomain,
                            code: errorCode.rawValue,
                            userInfo: nil)
        
        self.view?.extensionContext.cancelRequest(withError: error)
    }
}
