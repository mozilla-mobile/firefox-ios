// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common
import AuthenticationServices

let CredentialProviderAuthenticationDelay = 0.25

final class CredentialProviderPresenter {
    weak var view: CredentialProviderViewProtocol?
    public let profile: Profile
    private let appAuthenticator: AppAuthenticator
    private let logger: Logger

    init(view: CredentialProviderViewProtocol,
         profile: Profile = BrowserProfile(localName: "profile"),
         appAuthenticator: AppAuthenticator = AppAuthenticator(),
         logger: Logger = DefaultLogger.shared) {
        self.view = view
        self.profile = profile
        self.appAuthenticator = appAuthenticator
        self.logger = logger
    }

    func extensionConfigurationRequested() {
        view?.showWelcome()
    }

    func showPasscodeRequirement() {
        view?.showPasscodeRequirement()
    }

    func credentialProvisionRequested(for credentialIdentity: ASPasswordCredentialIdentity) {
        let maxRetries = 3
        var currentRetry = 0

        guard profile.logins.reopenIfClosed() == nil else {
            cancel(with: .failed)
            return
        }

        guard let id = credentialIdentity.recordIdentifier else { return }

        func attemptProvision() {
            profile.logins.getLogin(id: id, completionHandler: { [weak self] result in
                switch result {
                case .failure:
                    self?.cancel(with: .failed)
                case .success(let record):
                    if let passwordCredential = record?.passwordCredential {
                        self?.view?.extensionContext.completeRequest(
                            withSelectedCredential: passwordCredential)
                    } else {
                        if currentRetry < maxRetries {
                            currentRetry += 1
                            self?.logger.log(
                                "Failed to retrieve credentials. Will retry. Retry #\(currentRetry)",
                                level: .warning,
                                category: .autofill
                            )
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                attemptProvision()
                            }
                        } else {
                            self?.logger.log(
                                "Failed to retrieve credentials after all \(maxRetries) attempts. No further retries. Will cancel the request with `userInteractionRequired` error.",
                                level: .warning,
                                category: .autofill
                            )
                            self?.cancel(with: .userInteractionRequired)
                        }
                    }
                }
            })
        }

        attemptProvision()
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
