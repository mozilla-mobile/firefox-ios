// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common
@preconcurrency import AuthenticationServices

let CredentialProviderAuthenticationDelay = 0.25

@MainActor
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
        guard profile.logins.reopenIfClosed() == nil else {
            cancel(with: .failed)
            return
        }

        guard let id = credentialIdentity.recordIdentifier else { return }

        attemptProvision(id: id, currentRetry: 0)
    }

    /// Helper method to retry provisioning up to 3 times after a delay.
    private func attemptProvision(id: String, currentRetry: Int) {
        let maxRetries = 3

        profile.logins.getLogin(id: id, completionHandler: { result in
            ensureMainThread { [weak self] in
                switch result {
                case .failure:
                    self?.cancel(with: .failed)
                case .success(let record):
                    if let passwordCredential = record?.passwordCredential {
                        self?.view?.extensionContext.completeRequest(
                            withSelectedCredential: passwordCredential)
                    } else {
                        if currentRetry < maxRetries {
                            let updatedRetry = currentRetry + 1
                            self?.logger.log(
                                "Failed to retrieve credentials. Will retry. Retry #\(updatedRetry)",
                                level: .warning,
                                category: .autofill
                            )
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                                self?.attemptProvision(id: id, currentRetry: updatedRetry)
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
            }
        })
    }

    func showCredentialList(for serviceIdentifiers: [ASCredentialServiceIdentifier]) {
        if self.profile.logins.reopenIfClosed() != nil {
            cancel(with: .failed)
        } else {
            profile.logins.listLogins(completionHandler: { result in
                ensureMainThread { [weak self] in
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
                    self.showCredentialList(for: serviceIdentifiers)
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
