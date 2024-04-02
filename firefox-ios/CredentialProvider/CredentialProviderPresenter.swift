// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import AuthenticationServices

let CredentialProviderAuthenticationDelay = 0.25

class CredentialProviderPresenter {
    weak var view: CredentialProviderViewProtocol?
    public let profile: Profile
    private let appAuthenticator: AppAuthenticator

    init(view: CredentialProviderViewProtocol,
         profile: Profile = BrowserProfile(localName: "profile"),
         appAuthenticator: AppAuthenticator = AppAuthenticator()) {
        self.view = view
        self.profile = profile
        self.appAuthenticator = appAuthenticator
    }

    func extensionConfigurationRequested() {
        view?.showWelcome()
    }

    func showPasscodeRequirement() {
        view?.showPasscodeRequirement()
    }

    func credentialProvisionRequested(for credentialIdentity: ASPasswordCredentialIdentity) {
        if self.profile.logins.reopenIfClosed() != nil {
            cancel(with: .failed)
        } else if let id = credentialIdentity.recordIdentifier {
            profile.logins.getLogin(id: id, completionHandler: { [weak self] result in
                switch result {
                case .failure:
                    self?.cancel(with: .failed)
                case .success(let record):
                    if let passwordCredential = record?.passwordCredential {
                        self?.view?.extensionContext.completeRequest(
                            withSelectedCredential: passwordCredential,
                            completionHandler: nil
                        )
                    } else {
                        self?.cancel(with: .userInteractionRequired)
                    }
                }
            })
        }
    }

    func showCredentialList(for serviceIdentifiers: [ASCredentialServiceIdentifier]) {
        if self.profile.logins.reopenIfClosed() != nil {
            cancel(with: .failed)
        } else {
            profile.logins.listLogins(completionHandler: { [weak self] result in
                switch result {
                case .failure:
                    self?.cancel(with: .failed)
                case .success(let loginRecords):
                    var sortedLogins = loginRecords.sorted(by: <)
                    for (index, element) in sortedLogins.enumerated() {
                        if let identifier = serviceIdentifiers
                            .first?
                            .identifier.asURL?.domainURL
                            .absoluteString.titleFromHostname,
                           element.passwordCredentialIdentity.serviceIdentifier.identifier.contains(identifier) {
                            sortedLogins.remove(at: index)
                            sortedLogins.insert(element, at: 0)
                        }
                    }
                    let dataSource = sortedLogins.map { ($0.passwordCredentialIdentity, $0.passwordCredential) }
                    DispatchQueue.main.async {
                        self?.view?.show(itemList: dataSource)
                    }
                }
            })
        }
    }

    func credentialList(for serviceIdentifiers: [ASCredentialServiceIdentifier]) {
        // Force a short delay before we trigger authentication.
        // See https://github.com/mozilla-mobile/firefox-ios/issues/9354
        DispatchQueue.main.asyncAfter(deadline: .now() + CredentialProviderAuthenticationDelay) {
            self.appAuthenticator.authenticateWithDeviceOwnerAuthentication { result in
                switch result {
                case .success:
                    // Move to the main thread because a state update triggers UI changes.
                    DispatchQueue.main.async { [unowned self] in
                        self.showCredentialList(for: serviceIdentifiers)
                    }
                case .failure:
                    self.cancel(with: .userCanceled)
                }
            }
        }
    }
}

private extension CredentialProviderPresenter {
    func cancel(with errorCode: ASExtensionError.Code) {
        self.view?.extensionContext.cancelRequest(withError: ASExtensionError(errorCode))
    }
}
