// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common
import AuthenticationServices

let CredentialProviderAuthenticationDelay = 0.25

// TODO: FXIOS-13149 this class is marked as unchecked sendable because
// of a weak view reference. This follow up ticket is to see if this
// actually makes sense.
final class CredentialProviderPresenter: @unchecked Sendable {
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

        guard profile.logins.reopenIfClosed() == nil else {
            cancel(with: .failed)
            return
        }

        guard let id = credentialIdentity.recordIdentifier else { return }

        func attemptProvision(currentRetry: Int) {
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
                            let updatedRetry = currentRetry + 1
                            self?.logger.log(
                                "Failed to retrieve credentials. Will retry. Retry #\(updatedRetry)",
                                level: .warning,
                                category: .autofill
                            )
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                attemptProvision(currentRetry: updatedRetry)
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

        attemptProvision(currentRetry: 0)
    }
}

private extension CredentialProviderPresenter {
    func cancel(with errorCode: ASExtensionError.Code) {
        self.view?.extensionContext.cancelRequest(withError: ASExtensionError(errorCode))
    }
}
