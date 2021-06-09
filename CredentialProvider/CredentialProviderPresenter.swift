/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import AuthenticationServices

@available(iOS 12, *)
class CredentialProviderPresenter {
    weak var view: CredentialProviderViewProtocol?
    private let profile: Profile
    
    init(view: CredentialProviderViewProtocol, profile: Profile = ExtensionProfile(localName: "profile")) {
        self.view = view
        self.profile = profile
    }
    
    func extensionConfigurationRequested() {
        view?.displayWelcome()
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
        if let openError = self.profile.logins.reopenIfClosed() {
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
    
    func credentialList(for serviceIdentifiers: [ASCredentialServiceIdentifier]) {
        if let openError = self.profile.logins.reopenIfClosed() {
            cancelWith(.failed)
        } else {
            profile.logins.list().upon {[weak self] result in
                switch result {
                case .failure:
                    self?.cancelWith(.failed)
                case .success(let loginRecords):
                    var sortedLogins = loginRecords.sorted { $0.passwordCredentialIdentity.serviceIdentifier.identifier.titleFromHostname() < $1.passwordCredentialIdentity.serviceIdentifier.identifier.titleFromHostname()
                    }
                    for (index, element) in sortedLogins.enumerated() {
                        if element.passwordCredentialIdentity.serviceIdentifier.identifier.asURL?.domainURL == serviceIdentifiers.first?.identifier.asURL?.domainURL {
                            sortedLogins.remove(at: index)
                            sortedLogins.insert(element, at: 0)
                        }
                    }
                    
                    let dataSource = sortedLogins.map { ($0.passwordCredentialIdentity, $0.passwordCredential) }
                    DispatchQueue.main.async {
                        self?.view?.display(itemList: dataSource)
                    }
                }
            }
        }
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
